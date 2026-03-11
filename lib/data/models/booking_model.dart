import 'package:courtify/domain/entities/booking.dart';
import 'slot_model.dart';

class BookingModel extends Booking {
  BookingModel({
    required super.id,
    required super.userId,
    super.userName,
    super.paymentMethodId,
    required super.totalPrice,
    required super.status,
    required super.paymentStatus,
    super.cancelReason,
    required super.createdAt,
    super.slots,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // Nested structure from joined query: booking -> booking_detail -> slot -> badminton_court
    final details = json['booking_detail'] as List? ?? [];
    final slots = details.map((d) {
      final slotJson = d['slot'] as Map<String, dynamic>;
      return SlotModel.fromJson(slotJson);
    }).toList();

    final userJson = json['users'] as Map<String, dynamic>?;

    return BookingModel(
      id: json['booking_id'] as int,
      userId: json['user_id'] as int,
      userName: userJson?['full_name'] as String?,
      paymentMethodId: json['payment_method_id'] as int?,
      totalPrice: (json['total_price'] as num).toDouble(),
      status: _parseStatus(json['booking_status'] as String),
      paymentStatus: _parsePaymentStatus(json['payment_status'] as String),
      cancelReason: json['cancel_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      slots: slots,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': id,
      'user_id': userId,
      'payment_method_id': paymentMethodId,
      'total_price': totalPrice,
      'booking_status': status.name.toUpperCase(),
      'payment_status': paymentStatus.name.toUpperCase(),
      'cancel_reason': cancelReason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static BookingStatus _parseStatus(String status) {
    return BookingStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == status.toUpperCase(),
      orElse: () => BookingStatus.pending,
    );
  }

  static PaymentStatus _parsePaymentStatus(String status) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == status.toUpperCase(),
      orElse: () => PaymentStatus.unpaid,
    );
  }
}
