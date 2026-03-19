import '../entities/payment.dart';

abstract class PaymentsRepository {
  Future<PaymentEntity?> createPayment({
    required String bookingId,
    required int amount,
  });

  Future<PaymentEntity?> checkPaymentStatus(int orderCode);

  Future<void> cancelPayOSPayment(int orderCode);

  Future<PaymentEntity?> createCashPayment({
    required String bookingId,
    List<String>? slotIds,
  });

  Future<PaymentEntity?> confirmPayment({
    required String bookingId,
    required String transactionId,
    List<String>? slotIds,
  });

  Future<PaymentEntity?> getPaymentByBookingId(String bookingId);
}
