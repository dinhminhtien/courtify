import 'court.dart';

class Slot {
  final int id;
  final int courtId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int priceTypeId;
  final double? price;
  final String? priceName;
  final bool isLocked;
  final Court? court;

  Slot({
    required this.id,
    required this.courtId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.priceTypeId,
    this.price,
    this.priceName,
    required this.isLocked,
    this.court,
  });
}
