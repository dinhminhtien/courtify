import '../../domain/entities/payment.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.id,
    required super.bookingId,
    required super.amount,
    required super.paymentMethod,
    super.status = 'PENDING',
    super.transactionId,
    super.checkoutUrl,
    super.qrCode,
    super.paymentLinkId,
    super.orderCode,
    super.accountNumber,
    super.accountName,
    super.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
    id: json['id'] as String? ?? '',
    bookingId: json['booking_id'] as String? ?? '',
    amount: json['amount'] as int? ?? 0,
    paymentMethod: json['payment_method'] as String? ?? 'cash',
    status: json['status'] as String? ?? 'PENDING',
    transactionId: json['transaction_id'] as String?,
    checkoutUrl: json['checkout_url'] as String?,
    qrCode: json['qr_code'] as String?,
    paymentLinkId: json['payment_link_id'] as String?,
    orderCode: json['order_code'] as int?,
    accountNumber: json['account_number'] as String?,
    accountName: json['account_name'] as String?,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'booking_id': bookingId,
    'amount': amount,
    'status': status,
    'transaction_id': transactionId,
    'checkout_url': checkoutUrl,
    'qr_code': qrCode,
    'payment_link_id': paymentLinkId,
    'order_code': orderCode,
    'account_number': accountNumber,
    'account_name': accountName,
  };
}
