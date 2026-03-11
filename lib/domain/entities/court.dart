enum CourtStatus { available, maintenance }

class Court {
  final int id;
  final String name;
  final String? type;
  final CourtStatus status;

  Court({
    required this.id,
    required this.name,
    this.type,
    required this.status,
  });
}
