import 'package:fixgo/core/domain/enums/user_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.createdAt,
    this.phoneNumber,
    this.photoUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final DateTime createdAt;
  final String? phoneNumber;
  final String? photoUrl;

  AppUser copyWith({
    String? id,
    String? fullName,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    String? phoneNumber,
    String? photoUrl,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
