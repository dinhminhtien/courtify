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
    id: json['id'] as String,
    courtId: json['court_id'] as String,
    slotDate: DateTime.parse(json['slot_date'] as String),
    startTime: json['start_time'] as String,
    endTime: json['end_time'] as String,
    price: json['price'] as int,
    status: json['status'] as String? ?? 'AVAILABLE',
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
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
