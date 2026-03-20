import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/payments_repository.dart';
import '../../data/repositories/supabase_payments_repository.dart';
import '../../../courts/presentation/providers/courts_provider.dart';
import '../../../booking/presentation/providers/bookings_provider.dart';

// ─── Repository Provider ──────────────────────────────────────────────────────

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return SupabasePaymentsRepository();
});

// ─── Payment State ────────────────────────────────────────────────────────────

class PaymentState {
  final bool isProcessing;
  final bool paymentSuccess;
  final bool isPolling;
  final String? error;
  final String? transactionId;
  final String? checkoutUrl;
  final String? qrCode;
  final int? orderCode;
  final String? accountNumber;
  final String? accountName;

  const PaymentState({
    this.isProcessing = false,
    this.paymentSuccess = false,
    this.isPolling = false,
    this.error,
    this.transactionId,
    this.checkoutUrl,
    this.qrCode,
    this.orderCode,
    this.accountNumber,
    this.accountName,
  });

  PaymentState copyWith({
    bool? isProcessing,
    bool? paymentSuccess,
    bool? isPolling,
    String? error,
    String? transactionId,
    String? checkoutUrl,
    String? qrCode,
    int? orderCode,
    String? accountNumber,
    String? accountName,
    bool clearError = false,
  }) {
    return PaymentState(
      isProcessing: isProcessing ?? this.isProcessing,
      paymentSuccess: paymentSuccess ?? this.paymentSuccess,
      isPolling: isPolling ?? this.isPolling,
      error: clearError ? null : (error ?? this.error),
      transactionId: transactionId ?? this.transactionId,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      qrCode: qrCode ?? this.qrCode,
      orderCode: orderCode ?? this.orderCode,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
    );
  }
}

// ─── Payment Notifier ─────────────────────────────────────────────────────────

class PaymentNotifier extends Notifier<PaymentState> {
  PaymentsRepository? _paymentsRepository;

  @override
  PaymentState build() {
    _paymentsRepository = ref.watch(paymentsRepositoryProvider);
    return const PaymentState();
  }

  Future<void> initiatePayment({
    required String bookingId,
    required int amount,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final payment = await _paymentsRepository!.createPayment(
        bookingId: bookingId,
        amount: amount,
      );
      
      if (payment != null) {
        state = state.copyWith(
          isProcessing: false,
          isPolling: true,
          checkoutUrl: payment.checkoutUrl,
          qrCode: payment.qrCode,
          orderCode: payment.orderCode,
          accountNumber: payment.accountNumber,
          accountName: payment.accountName,
        );
      } else {
        state = state.copyWith(isProcessing: false, error: 'Failed to create PayOS link');
      }
    } catch (e) {
      debugPrint('Create payment record error: $e');
      state = state.copyWith(isProcessing: false, error: e.toString());
    }
  }

  Future<void> checkStatus() async {
    final orderCode = state.orderCode;
    if (orderCode == null || state.paymentSuccess) return;

    try {
      final payment = await _paymentsRepository!.checkPaymentStatus(orderCode);
      debugPrint('Polling result for $orderCode: ${payment?.status}');
      
      if (payment?.status == 'PAID') {
        debugPrint('MATCH! Setting paymentSuccess to true');
        state = state.copyWith(
          isPolling: false,
          paymentSuccess: true,
          transactionId: payment?.transactionId,
          clearError: true,
        );
        // Refresh relevant screens immediately
        _triggerRefreshes();
      } else if (payment?.status == 'FAILED' || payment?.status == 'CANCELLED') {
         state = state.copyWith(
          isPolling: false,
          error: 'Thanh toán thất bại hoặc đã bị hủy',
        );
      }
    } catch (e) {
      debugPrint('Check status error: $e');
    }
  }

  Future<void> cancelPayment() async {
    final orderCode = state.orderCode;
    if (orderCode == null) return;
    
    try {
      await _paymentsRepository!.cancelPayOSPayment(orderCode);
      state = state.copyWith(isPolling: false);
    } catch (e) {
      debugPrint('Cancel payment error: $e');
    }
  }

  Future<void> confirmPayment({
    required String bookingId,
    List<String>? slotIds,
  }) async {
    try {
      final transactionId = 'TXN-${DateTime.now().millisecondsSinceEpoch}';
      await _paymentsRepository!.confirmPayment(
        bookingId: bookingId,
        transactionId: transactionId,
        slotIds: slotIds,
      );
      state = state.copyWith(
        isPolling: false,
        paymentSuccess: true,
        transactionId: transactionId,
      );
      _triggerRefreshes();
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
      await _paymentsRepository!.createCashPayment(
        bookingId: bookingId,
        slotIds: slotIds,
      );
      state = state.copyWith(
        isProcessing: false,
        paymentSuccess: true,
        transactionId: 'CASH-${DateTime.now().millisecondsSinceEpoch}',
      );
      _triggerRefreshes();
    } catch (e) {
      debugPrint('Confirm cash payment error: $e');
      state = state.copyWith(isProcessing: false, error: e.toString());
    }
  }

  void setPolling(bool value) {
    state = state.copyWith(isPolling: value);
  }

  void _triggerRefreshes() {
    // Force refresh the courts state to show updated slot visibility
    ref.read(courtsProvider.notifier).loadSlots();
    // Refresh user's booking history
    ref.read(bookingsProvider.notifier).loadUserBookings();
  }

  void reset() {
    state = const PaymentState();
  }
}

// Helper to avoid circular imports? No, I can just use ref.read

final paymentProvider = NotifierProvider<PaymentNotifier, PaymentState>(() {
  return PaymentNotifier();
});

