import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/api/supabase_client.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../models/booking_model.dart';

class SupabaseBookingsRepository implements BookingsRepository {
  final SupabaseClient _client = SupabaseClientManager.instance.client;

  @override
  Future<BookingEntity?> createBooking({
    required List<String> slotIds,
    required String courtId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    try {
      final holdExpiresAt = DateTime.now().add(const Duration(minutes: 10)).toUtc().toIso8601String();
      
      // Insert multiple rows, one for each slot
      final List<Map<String, dynamic>> bookingsToInsert = slotIds.map((slotId) => {
        'user_id': userId,
        'court_id': courtId,
        'slot_id': slotId,
        'status': 'PENDING',
        'payment_status': 'UNPAID',
        'hold_expires_at': holdExpiresAt,
      }).toList();

      // Transaction-like approach: Create bookings AND update slots
      final data = await _client.from('bookings').insert(bookingsToInsert).select('*, court_slots(*), courts(*)');
      
      // Update the slots themselves to HOLD status
      await _client
          .from('court_slots')
          .update({'status': 'HOLD'})
          .inFilter('id', slotIds);

      if ((data as List).isEmpty) return null;
      
      return BookingModel.fromJson(data.first);
    } catch (e) {
      debugPrint('Create booking error: $e');
      rethrow;
    }
  }

  @override
  Future<List<BookingEntity>> getUserBookings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final data = await _client
          .from('bookings')
          .select('*, court_slots(*), courts(*), users(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (data as List).map((e) => BookingModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Get user bookings error: $e');
      return [];
    }
  }

  @override
  Future<List<BookingEntity>> getAllBookings() async {
    try {
      final data = await _client
          .from('bookings')
          .select('*, court_slots(*), courts(*), users(*)')
          .order('created_at', ascending: false);

      return (data as List).map((e) => BookingModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Get all bookings error: $e');
      return [];
    }
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    try {
      // 1. Get the booking to find group info
      final bookingDetails = await _client
          .from('bookings')
          .select('user_id, court_id, hold_expires_at, slot_id')
          .eq('id', bookingId)
          .maybeSingle();

      if (bookingDetails == null) return;

      final userId = bookingDetails['user_id'];
      final courtId = bookingDetails['court_id'];
      final holdExpiresAt = bookingDetails['hold_expires_at'];

      List<String> slotIds = [];

      if (holdExpiresAt != null) {
        // Group cancellation
        final related = await _client
            .from('bookings')
            .select('id, slot_id')
            .eq('user_id', userId)
            .eq('court_id', courtId)
            .eq('hold_expires_at', holdExpiresAt);

        slotIds = (related as List).map((r) => r['slot_id'] as String).toList();

        // Update all related bookings
        await _client
            .from('bookings')
            .update({'status': 'CANCELLED'})
            .eq('user_id', userId)
            .eq('court_id', courtId)
            .eq('hold_expires_at', holdExpiresAt);
      } else {
        // Single cancellation
        slotIds = [bookingDetails['slot_id'] as String];
        await _client
            .from('bookings')
            .update({'status': 'CANCELLED'})
            .eq('id', bookingId);
      }

      // 2. Release slots back to AVAILABLE
      if (slotIds.isNotEmpty) {
        await _client
            .from('court_slots')
            .update({'status': 'AVAILABLE'})
            .inFilter('id', slotIds);
      }
    } catch (e) {
      debugPrint('Cancel booking error: $e');
      rethrow;
    }
  }

  @override
  Future<void> confirmBooking(String bookingId) async {
    try {
      // 1. Get the booking to find group info
      final bookingDetails = await _client
          .from('bookings')
          .select('user_id, court_id, hold_expires_at, slot_id')
          .eq('id', bookingId)
          .maybeSingle();

      if (bookingDetails == null) return;

      final userId = bookingDetails['user_id'];
      final courtId = bookingDetails['court_id'];
      final holdExpiresAt = bookingDetails['hold_expires_at'];

      List<String> slotIds = [];

      if (holdExpiresAt != null) {
        // Group confirmation
        final related = await _client
            .from('bookings')
            .select('slot_id')
            .eq('user_id', userId)
            .eq('court_id', courtId)
            .eq('hold_expires_at', holdExpiresAt);

        slotIds = (related as List).map((r) => r['slot_id'] as String).toList();

        await _client
            .from('bookings')
            .update({'status': 'CONFIRMED'})
            .eq('user_id', userId)
            .eq('court_id', courtId)
            .eq('hold_expires_at', holdExpiresAt);
      } else {
        // Single confirmation
        slotIds = [bookingDetails['slot_id'] as String];
        await _client
            .from('bookings')
            .update({'status': 'CONFIRMED'})
            .eq('id', bookingId);
      }

      // 2. Update slot status to BOOKED
      if (slotIds.isNotEmpty) {
        await _client
            .from('court_slots')
            .update({'status': 'BOOKED'})
            .inFilter('id', slotIds);
      }
    } catch (e) {
      debugPrint('Confirm booking error: $e');
      rethrow;
    }
  }

  @override
  Future<void> completeBooking(String bookingId) async {
    try {
      await _client
          .from('bookings')
          .update({'status': 'COMPLETED'}).eq('id', bookingId);
    } catch (e) {
      debugPrint('Complete booking error: $e');
      rethrow;
    }
  }

}

