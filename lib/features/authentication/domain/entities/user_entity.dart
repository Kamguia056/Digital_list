// lib/features/authentication/domain/entities/user_entity.dart
class UserEntity {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? deviceId;
  final DateTime? deviceLockedUntil;
  final bool isBlocked;
  final DateTime? createdAt;

  const UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.deviceId,
    this.deviceLockedUntil,
    this.isBlocked = false,
    this.createdAt,
  });

  bool get isStudent => role == 'student';
  bool get isTeacher => role == 'teacher';
  bool get isAdmin => role == 'admin';
}
