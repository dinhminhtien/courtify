class CourtSlotEntity {
  final String id;
  final String courtId;
  final DateTime slotDate;
  final String startTime;
  final String endTime;
  final int price;
  final String status; // AVAILABLE | BOOKED | HOLD | BLOCKED
  final DateTime? createdAt;

  const CourtSlotEntity({
    required this.id,
    required this.courtId,
    required this.slotDate,
    required this.startTime,
    required this.endTime,
    required this.price,
    this.status = 'AVAILABLE',
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'startTime': startTime.length >= 5 ? startTime.substring(0, 5) : startTime,
    'endTime': endTime.length >= 5 ? endTime.substring(0, 5) : endTime,
    'price': price,
    'status': status,
    'date': slotDate,
    'courtId': courtId,
  };
}
