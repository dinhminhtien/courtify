import 'package:courtify/domain/entities/slot.dart';
import 'court_model.dart';

class SlotModel extends Slot {
  SlotModel({
    required super.id,
    required super.courtId,
    required super.date,
    required super.startTime,
    required super.endTime,
    required super.priceTypeId,
    super.price,
    super.priceName,
    required super.isLocked,
    super.court,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      id: json['slot_id'] as int,
      courtId: json['badminton_court_id'] as int,
      date: DateTime.parse(json['date'] as String),
      startTime: json['time_start'] as String,
      endTime: json['time_end'] as String,
      priceTypeId: json['price_type_id'] as int,
      price: json['price_type'] != null ? (json['price_type']['price'] as num).toDouble() : null,
      priceName: json['price_type'] != null ? json['price_type']['name_type'] as String : null,
      isLocked: json['is_locked'] as bool? ?? false,
      court: json['badminton_court'] != null 
          ? CourtModel.fromJson(json['badminton_court'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slot_id': id,
      'badminton_court_id': courtId,
      'date': date.toIso8601String().split('T')[0],
      'time_start': startTime,
      'time_end': endTime,
      'price_type_id': priceTypeId,
      'is_locked': isLocked,
    };
  }
}
