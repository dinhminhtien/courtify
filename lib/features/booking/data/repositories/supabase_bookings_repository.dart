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
      // Basic implementation for a single slot for now, as per original logic
      final data = await _client.from('bookings').insert({
        'user_id': userId,
        'court_id': courtId,
        'slot_id': slotIds.first,
        'status': 'PENDING',
        'payment_status': 'UNPAID',
        'hold_expires_at':
            DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
      }).select('*, court_slots(*), courts(*)').single();

      return BookingModel.fromJson(data);
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

      // Create Notification
      final booking = await _client.from('bookings').select('user_id').eq('id', bookingId).single();
      await _createNotification(
        userId: booking['user_id'],
        title: 'Booking đã hủy',
        content: 'Booking $bookingId của bạn đã được hủy thành công.',
        type: 'reminder',
        referenceId: bookingId,
      );
    } catch (e) {
      debugPrint('Cancel booking error: $e');
      rethrow;
    }
  }

  @override
  Future<void> confirmBooking(String bookingId) async {
    try {
      await _client
          .from('bookings')
          .update({'status': 'CONFIRMED'}).eq('id', bookingId);
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

      // Create Notification
      final booking = await _client.from('bookings').select('user_id').eq('id', bookingId).single();
      await _createNotification(
        userId: booking['user_id'],
        title: 'Booking hoàn tất',
        content: 'Cảm ơn bạn đã sử dụng dịch vụ! Booking $bookingId đã hoàn tất.',
        type: 'reminder',
        referenceId: bookingId,
      );
    } catch (e) {
      debugPrint('Complete booking error: $e');
      rethrow;
    }
  }

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String content,
    required String type,
    String? referenceId,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'content': content,
        'type': type,
        'reference_id': referenceId,
        'is_read': false,
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }
}

