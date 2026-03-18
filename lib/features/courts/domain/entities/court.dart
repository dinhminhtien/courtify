class CourtEntity {
  final String id;
  final int courtNumber;
  final DateTime? createdAt;

  const CourtEntity({required this.id, required this.courtNumber, this.createdAt});

  String get label => 'Sân $courtNumber';
}
