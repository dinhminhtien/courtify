import '../../../auth/data/models/user_model.dart';
import '../../../courts/data/models/court_model.dart';
import '../../../courts/data/models/court_slot_model.dart';
import '../../domain/entities/booking.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.userId,
    required super.courtId,
    required super.slotId,
    super.status = 'PENDING',
    super.paymentStatus = 'UNPAID',
    super.holdExpiresAt,
    super.createdAt,
    super.orderCode,
    super.slot,
    super.court,
    super.user,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
    id: json['id'] as String? ?? '',
    userId: json['user_id'] as String? ?? '',
    courtId: json['court_id'] as String? ?? '',
    slotId: json['slot_id'] as String? ?? '',
    status: json['status'] as String? ?? 'PENDING',
    paymentStatus: json['payment_status'] as String? ?? 'UNPAID',
    holdExpiresAt: json['hold_expires_at'] != null
        ? DateTime.tryParse(json['hold_expires_at'] as String)
        : null,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
    orderCode: json['order_code'] as int?,
    slot: json['court_slots'] != null
        ? CourtSlotModel.fromJson(json['court_slots'] as Map<String, dynamic>)
        : null,
    court: json['courts'] != null
        ? CourtModel.fromJson(json['courts'] as Map<String, dynamic>)
        : null,
    user: json['users'] != null
        ? UserModel.fromJson(json['users'] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'court_id': courtId,
    'slot_id': slotId,
    'status': status,
    'payment_status': paymentStatus,
    'hold_expires_at': holdExpiresAt?.toIso8601String(),
    'order_code': orderCode,
  };
}
