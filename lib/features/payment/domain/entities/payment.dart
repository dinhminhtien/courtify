class PaymentEntity {
  final String id;
  final String bookingId;
  final int amount;
  final String paymentMethod; // cash | bank_transfer
  final String status; // PENDING | SUCCESS | FAILED
  final String? transactionId;
  final String? checkoutUrl;
  final String? qrCode;
  final String? paymentLinkId;
  final int? orderCode;
  final String? accountNumber;
  final String? accountName;
  final DateTime? createdAt;

  const PaymentEntity({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.paymentMethod,
    this.status = 'PENDING',
    this.transactionId,
    this.checkoutUrl,
    this.qrCode,
    this.paymentLinkId,
    this.orderCode,
    this.accountNumber,
    this.accountName,
    this.createdAt,
  });
}
