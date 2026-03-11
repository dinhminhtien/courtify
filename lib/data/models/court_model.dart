import 'package:courtify/domain/entities/court.dart';

class CourtModel extends Court {
  CourtModel({
    required super.id,
    required super.name,
    super.type,
    required super.status,
  });

  factory CourtModel.fromJson(Map<String, dynamic> json) {
    return CourtModel(
      id: json['badminton_court_id'] as int,
      name: json['court_name'] as String,
      type: json['type_court'] as String?,
      status: _parseStatus(json['status_court'] as String),
    );
  }

  static CourtStatus _parseStatus(String status) {
    if (status.toUpperCase() == 'AVAILABLE') return CourtStatus.available;
    return CourtStatus.maintenance;
  }

  Map<String, dynamic> toJson() {
    return {
      'badminton_court_id': id,
      'court_name': name,
      'type_court': type,
      'status_court': status.name.toUpperCase(),
    };
  }
}
