class UserEntity {
  final String id;
  final String? email;
  final String? fullName;
  final String? phone;
  final String role; // 'customer' | 'owner'
  final DateTime? createdAt;

  const UserEntity({
    required this.id,
    this.email,
    this.fullName,
    this.phone,
    this.role = 'customer',
    this.createdAt,
  });

  bool get isOwner => role == 'owner';

  bool get isProfileComplete =>
      fullName != null &&
      fullName!.isNotEmpty &&
      phone != null &&
      phone!.isNotEmpty;
}
