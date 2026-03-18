import '../../domain/entities/payment.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.id,
    required super.bookingId,
    required super.amount,
    required super.paymentMethod,
    super.status = 'PENDING',
    super.transactionId,
    super.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
    id: json['id'] as String? ?? '',
    bookingId: json['booking_id'] as String? ?? '',
    amount: json['amount'] as int? ?? 0,
    paymentMethod: json['payment_method'] as String? ?? 'cash',
    status: json['status'] as String? ?? 'PENDING',
    transactionId: json['transaction_id'] as String?,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'booking_id': bookingId,
    'amount': amount,
    'payment_method': paymentMethod,
    'status': status,
    'transaction_id': transactionId,
  };
}
