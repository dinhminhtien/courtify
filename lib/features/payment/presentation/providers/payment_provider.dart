import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';

// ─── Payment State ────────────────────────────────────────────────────────────

class PaymentState {
  final bool isProcessing;
  final bool paymentSuccess;
  final bool isPolling;
  final String? error;
  final String? transactionId;

  const PaymentState({
    this.isProcessing = false,
    this.paymentSuccess = false,
    this.isPolling = false,
    this.error,
    this.transactionId,
  });

  PaymentState copyWith({
    bool? isProcessing,
    bool? paymentSuccess,
    bool? isPolling,
    String? error,
    String? transactionId,
    bool clearError = false,
  }) {
    return PaymentState(
      isProcessing: isProcessing ?? this.isProcessing,
      paymentSuccess: paymentSuccess ?? this.paymentSuccess,
      isPolling: isPolling ?? this.isPolling,
      error: clearError ? null : (error ?? this.error),
      transactionId: transactionId ?? this.transactionId,
    );
  }
}

// ─── Payment Notifier ─────────────────────────────────────────────────────────

class PaymentNotifier extends Notifier<PaymentState> {
  final PaymentsService _paymentsService = PaymentsService();

  @override
  PaymentState build() {
    return const PaymentState();
  }

  Future<void> initiatePayment({
    required String bookingId,
    required int amount,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      await _paymentsService.createPayment(
        bookingId: bookingId,
        amount: amount,
      );
    } catch (e) {
      debugPrint('Create payment record error: $e');
    }
    state = state.copyWith(isProcessing: false, isPolling: true);
  }

  Future<void> confirmPayment({
    required String bookingId,
    List<String>? slotIds,
  }) async {
    try {
      final transactionId = 'TXN-${DateTime.now().millisecondsSinceEpoch}';
      await _paymentsService.confirmPayment(
        bookingId: bookingId,
        transactionId: transactionId,
        slotIds: slotIds,
      );
      state = state.copyWith(
        isPolling: false,
        paymentSuccess: true,
        transactionId: transactionId,
      );
    } catch (e) {
      debugPrint('Confirm payment error: $e');
      state = state.copyWith(isPolling: false, error: e.toString());
    }
  }

  Future<void> confirmCashPayment({
    required String bookingId,
    List<String>? slotIds,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      await _paymentsService.createCashPayment(
        bookingId: bookingId,
        slotIds: slotIds,
      );
      state = state.copyWith(
        isProcessing: false,
        paymentSuccess: true,
        transactionId: 'CASH-${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      debugPrint('Confirm cash payment error: $e');
      state = state.copyWith(isProcessing: false, error: e.toString());
    }
  }

  void setPolling(bool value) {
    state = state.copyWith(isPolling: value);
  }

  void reset() {
    state = const PaymentState();
  }
}

// ─── Owner Dashboard State ────────────────────────────────────────────────────

class OwnerDashboardState {
  final List<Map<String, dynamic>> bookings;
  final bool isLoading;
  final String? error;

  const OwnerDashboardState({
    this.bookings = const [],
    this.isLoading = false,
    this.error,
  });

  OwnerDashboardState copyWith({
    List<Map<String, dynamic>>? bookings,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return OwnerDashboardState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Owner Dashboard Notifier ─────────────────────────────────────────────────

class OwnerDashboardNotifier extends Notifier<OwnerDashboardState> {
  final BookingsService _bookingsService = BookingsService();

  @override
  OwnerDashboardState build() {
    // Use Future.microtask to avoid triggering async state mutation during build
    Future.microtask(() => loadDashboardData());
    return const OwnerDashboardState();
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final bookings = await _bookingsService.getAllBookings();
      state = state.copyWith(
        bookings: bookings.map((b) => b.toDisplayMap()).toList(),
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Load dashboard error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> confirmBooking(String bookingId) async {
    await _bookingsService.confirmBooking(bookingId);
    await loadDashboardData();
  }

  Future<void> completeBooking(String bookingId) async {
    await _bookingsService.completeBooking(bookingId);
    await loadDashboardData();
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final paymentProvider = NotifierProvider<PaymentNotifier, PaymentState>(() {
  return PaymentNotifier();
});

final ownerDashboardProvider =
    NotifierProvider<OwnerDashboardNotifier, OwnerDashboardState>(() {
      return OwnerDashboardNotifier();
    });
