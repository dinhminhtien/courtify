import '../../../auth/domain/entities/user_entity.dart';
import '../../../courts/domain/entities/court.dart';
import '../../../courts/domain/entities/court_slot.dart';

class BookingEntity {
  final String id;
  final String userId;
  final String courtId;
  final String slotId;
  final String status; // PENDING | CONFIRMED | COMPLETED | CANCELLED
  final String paymentStatus; // UNPAID | PAID
  final DateTime? holdExpiresAt;
  final DateTime? createdAt;
  final int? orderCode;
  final String? paymentMethod;

  
  // Joined fields
  final CourtSlotEntity? slot;
  final CourtEntity? court;
  final UserEntity? user;

  const BookingEntity({
    required this.id,
    required this.userId,
    required this.courtId,
    required this.slotId,
    this.status = 'PENDING',
    this.paymentStatus = 'UNPAID',
    this.holdExpiresAt,
    this.createdAt,
    this.orderCode,
    this.paymentMethod,
    this.slot,
    this.court,
    this.user,
  });


  Map<String, dynamic> toDisplayMap() {
    final slotDate = slot?.slotDate ?? DateTime.now();
    final customerName = user?.fullName ?? user?.email ?? 'Khách hàng';
    final avatarLetter = customerName.isNotEmpty
        ? customerName[0].toUpperCase()
        : 'K';
    return {
      'id': id,
      'courtNumber': court?.courtNumber ?? 0,
      'courtLabel': court?.label ?? 'Sân',
      'dateFormatted':
          '${slotDate.day.toString().padLeft(2, '0')}/${slotDate.month.toString().padLeft(2, '0')}/${slotDate.year}',
      'date':
          '${slotDate.day.toString().padLeft(2, '0')}/${slotDate.month.toString().padLeft(2, '0')}/${slotDate.year}',
      'startTime': slot?.startTime != null && slot!.startTime.length >= 5
          ? slot!.startTime.substring(0, 5)
          : (slot?.startTime ?? ''),
      'endTime': slot?.endTime != null && slot!.endTime.length >= 5
          ? slot!.endTime.substring(0, 5)
          : (slot?.endTime ?? ''),
      'price': slot?.price ?? 0,
      'status': status,
      'paymentStatus': paymentStatus,
      'customerName': customerName,
      'avatarLetter': avatarLetter,
      'paymentMethod': paymentMethod ?? 'CHƯA CÓ',
      'createdAt': createdAt?.toIso8601String(),
      'isUpcoming': holdExpiresAt != null
          ? holdExpiresAt!.isAfter(DateTime.now())
          : (status == 'PENDING' || status == 'CONFIRMED'),
    };

  }
}
