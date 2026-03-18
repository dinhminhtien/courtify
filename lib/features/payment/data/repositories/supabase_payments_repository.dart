import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/api/supabase_client.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payments_repository.dart';
import '../models/payment_model.dart';

class SupabasePaymentsRepository implements PaymentsRepository {
  final SupabaseClient _client = SupabaseClientManager.instance.client;

  @override
  Future<PaymentEntity?> createPayment({
    required String bookingId,
    required int amount,
  }) async {
    try {
      final data = await _client.from('payments').insert({
        'booking_id': bookingId,
        'amount': amount,
        'status': 'UNPAID',
      }).select().single();

      return PaymentModel.fromJson(data);
    } catch (e) {
      debugPrint('Create payment error: $e');
      rethrow;
    }
  }

  @override
  Future<PaymentEntity?> createCashPayment({
    required String bookingId,
    List<String>? slotIds,
  }) async {
    try {
      List<String> finalSlotIds = slotIds ?? [];
      String? userId;
      String? courtId;
      String? rawHoldExpiresAt;
      int totalAmount = 0;

      if (finalSlotIds.isEmpty) {
        final bookingData = await _client
            .from('bookings')
            .select('slot_id, user_id, court_id, hold_expires_at')
            .eq('id', bookingId)
            .single();

        userId = bookingData['user_id'];
        courtId = bookingData['court_id'];
        rawHoldExpiresAt = bookingData['hold_expires_at'];

        if (rawHoldExpiresAt != null) {
          final groupBookings = await _client
              .from('bookings')
              .select('slot_id')
              .eq('user_id', userId as Object)
              .eq('court_id', courtId as Object)
              .eq('hold_expires_at', rawHoldExpiresAt as Object);
          finalSlotIds = (groupBookings as List)
              .map((b) => b['slot_id'] as String)
              .toList();
        } else {
          finalSlotIds = [bookingData['slot_id'] as String];
        }
      } else {
        final bookingData = await _client
            .from('bookings')
            .select('user_id, court_id, hold_expires_at')
            .eq('id', bookingId)
            .single();
        userId = bookingData['user_id'];
        courtId = bookingData['court_id'];
        rawHoldExpiresAt = bookingData['hold_expires_at'];
      }

      final slotsData = await _client
          .from('court_slots')
          .select('price')
          .inFilter('id', finalSlotIds);

      totalAmount =
          (slotsData as List).fold(0, (sum, s) => sum + (s['price'] as int));

      final data = await _client.from('payments').insert({
        'booking_id': bookingId,
        'amount': totalAmount,
        'transaction_id': 'CASH-${DateTime.now().millisecondsSinceEpoch}',
        'status': 'PENDING_CASH',
        'payment_method': 'cash',
      }).select().single();

      // Confirm bookings immediately for cash payment
      if (rawHoldExpiresAt != null && userId != null && courtId != null) {
        await _client.from('bookings').update({
          'payment_status': 'PENDING_CASH',
          'status': 'CONFIRMED'
        }).eq('user_id', userId as Object).eq('court_id', courtId as Object).eq(
          'hold_expires_at',
          rawHoldExpiresAt as Object,
        );
      } else {
        await _client.from('bookings').update({
          'payment_status': 'PENDING_CASH',
          'status': 'CONFIRMED'
        }).eq('id', bookingId);
      }

      // Update slots to BOOKED
      for (final id in finalSlotIds) {
        await _client.from('court_slots').update({'status': 'BOOKED'}).eq(
          'id',
          id,
        );
      }

      return PaymentModel.fromJson(data);
    } catch (e) {
      debugPrint('Create cash payment error: $e');
      rethrow;
    }
  }

  @override
  Future<PaymentEntity?> confirmPayment({
    required String bookingId,
    required String transactionId,
    List<String>? slotIds,
  }) async {
    try {
      await _client.from('payments').update({
        'status': 'PAID',
        'transaction_id': transactionId
      }).eq('booking_id', bookingId);

      List<String> finalSlotIds = slotIds ?? [];
      String? userId;
      String? courtId;
      String? rawHoldExpiresAt;

      if (finalSlotIds.isEmpty) {
        final booking = await _client
            .from('bookings')
            .select('slot_id, user_id, court_id, hold_expires_at')
            .eq('id', bookingId)
            .single();

        userId = booking['user_id'];
        courtId = booking['court_id'];
        rawHoldExpiresAt = booking['hold_expires_at'];

        if (rawHoldExpiresAt != null) {
          final groupBookings = await _client
              .from('bookings')
              .select('slot_id')
              .eq('user_id', userId as Object)
              .eq('court_id', courtId as Object)
              .eq('hold_expires_at', rawHoldExpiresAt as Object);
          finalSlotIds = (groupBookings as List)
              .map((b) => b['slot_id'] as String)
              .toList();
        } else {
          finalSlotIds = [booking['slot_id'] as String];
        }
      } else {
        final bookingData = await _client
            .from('bookings')
            .select('user_id, court_id, hold_expires_at')
            .eq('id', bookingId)
            .single();
        userId = bookingData['user_id'];
        courtId = bookingData['court_id'];
        rawHoldExpiresAt = bookingData['hold_expires_at'];
      }

      // Update all bookings in same group
      if (rawHoldExpiresAt != null && userId != null && courtId != null) {
        await _client.from('bookings').update({
          'payment_status': 'PAID',
          'status': 'CONFIRMED'
        }).eq('user_id', userId as Object).eq('court_id', courtId as Object).eq(
          'hold_expires_at',
          rawHoldExpiresAt as Object,
        );
      } else {
        await _client.from('bookings').update({
          'payment_status': 'PAID',
          'status': 'CONFIRMED'
        }).eq('id', bookingId);
      }

      // Update slots to BOOKED
      for (final id in finalSlotIds) {
        await _client.from('court_slots').update({'status': 'BOOKED'}).eq(
          'id',
          id,
        );
      }

      final data = await _client
          .from('payments')
          .select()
          .eq('booking_id', bookingId)
          .single();
      return PaymentModel.fromJson(data);
    } catch (e) {
      debugPrint('Confirm payment error: $e');
      rethrow;
    }
  }

  @override
  Future<PaymentEntity?> getPaymentByBookingId(String bookingId) async {
    try {
      final data = await _client
          .from('payments')
          .select()
          .eq('booking_id', bookingId)
          .maybeSingle();

      if (data == null) return null;
      return PaymentModel.fromJson(data);
    } catch (e) {
      debugPrint('Get payment error: $e');
      return null;
    }
  }
}
