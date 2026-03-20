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
      final holdExpiresAt = DateTime.now().add(const Duration(minutes: 10)).toIso8601String();
      
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
      await _client
          .from('bookings')
          .update({'status': 'CANCELLED'}).eq('id', bookingId);

      // Notification is handled by SQL Trigger
    } catch (e) {
      debugPrint('Cancel booking error: $e');
      rethrow;
    }
  }

  @override
  Future<void> confirmBooking(String bookingId) async {
    try {
      // 1. Get the booking to find the slots
      final booking = await _client.from('bookings').select('slot_id').eq('id', bookingId).single();
      final slotId = booking['slot_id'] as String;

      // 2. Update booking status
      await _client
          .from('bookings')
          .update({'status': 'CONFIRMED'}).eq('id', bookingId);
      
      // 3. Update slot status to BOOKED
      await _client
          .from('court_slots')
          .update({'status': 'BOOKED'})
          .eq('id', slotId);
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

      // Notification is handled by SQL Trigger
    } catch (e) {
      debugPrint('Complete booking error: $e');
      rethrow;
    }
  }

}

