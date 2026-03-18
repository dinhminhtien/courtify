import '../../domain/entities/court_slot.dart';

class CourtSlotModel extends CourtSlotEntity {
  const CourtSlotModel({
    required super.id,
    required super.courtId,
    required super.slotDate,
    required super.startTime,
    required super.endTime,
    required super.price,
    super.status = 'AVAILABLE',
    super.createdAt,
  });

  factory CourtSlotModel.fromJson(Map<String, dynamic> json) => CourtSlotModel(
    id: json['id'] as String? ?? '',
    courtId: json['court_id'] as String? ?? '',
    slotDate: json['slot_date'] != null
        ? (DateTime.tryParse(json['slot_date'] as String) ?? DateTime.now())
        : DateTime.now(),
    startTime: json['start_time'] as String? ?? '',
    endTime: json['end_time'] as String? ?? '',
    price: json['price'] as int? ?? 0,
    status: json['status'] as String? ?? 'AVAILABLE',
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'court_id': courtId,
    'slot_date': slotDate.toIso8601String().split('T')[0],
    'start_time': startTime,
    'end_time': endTime,
    'price': price,
    'status': status,
  };
}
