import '../../domain/entities/court.dart';

class CourtModel extends CourtEntity {
  const CourtModel({required super.id, required super.courtNumber, super.createdAt});

  factory CourtModel.fromJson(Map<String, dynamic> json) => CourtModel(
    id: json['id'] as String,
    courtNumber: json['court_number'] as int,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'court_number': courtNumber,
  };
}
