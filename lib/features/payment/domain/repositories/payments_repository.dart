import '../entities/payment.dart';

abstract class PaymentsRepository {
  Future<PaymentEntity?> createPayment({
    required String bookingId,
    required int amount,
  });

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
