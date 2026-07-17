import 'package:fixgo/core/domain/enums/user_role.dart';
import 'package:fixgo/domain/core/result.dart';
import 'package:fixgo/domain/core/entity.dart';
import 'package:fixgo/domain/core/value_objects.dart';

class AppUser extends Entity<AppUser> implements Validatable {
  const AppUser({
    required this.id, required this.fullName, required this.email,
    required this.role, required this.createdAt, this.phoneNumber,
    this.photoUrl, this.isActive = true,
  });

  @override final String id;
  final NonEmptyString fullName;
  final Email email;
  final UserRole role;
  final DateTime createdAt;
  final PhoneNumber? phoneNumber;
  final String? photoUrl;
  final bool isActive;

  @override bool get isValid => validationErrors.isEmpty;

  @override List<ValueFailure> get validationErrors => [];

  bool get isClient => role == UserRole.client;
  bool get isTechnician => role == UserRole.technician;

  AppUser copyWith({
    String? id, NonEmptyString? fullName, Email? email, UserRole? role,
    DateTime? createdAt, PhoneNumber? phoneNumber, String? photoUrl, bool? isActive,
  }) {
    return AppUser(
      id: id ?? this.id, fullName: fullName ?? this.fullName,
      email: email ?? this.email, role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt, phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl, isActive: isActive ?? this.isActive,
    );
  }

  static Result<AppUser> create({
    required String id, required String fullName, required String email,
    required UserRole role, String? phoneNumber, String? photoUrl,
  }) {
    final nameResult = NonEmptyString.create(fullName, maxLength: 100);
    final emailResult = Email.create(email);
    final Result<PhoneNumber?> phoneResult = phoneNumber != null && phoneNumber.isNotEmpty
        ? PhoneNumber.create(phoneNumber)
        : Result.ok<PhoneNumber?>(null);

    if (nameResult.isErr) return Result.err(nameResult.failure);
    if (emailResult.isErr) return Result.err(emailResult.failure);
    if (phoneResult.isErr) return Result.err(phoneResult.failure);

    return Result.ok(AppUser(
      id: id, fullName: nameResult.value, email: emailResult.value, role: role,
      createdAt: DateTime.now(), phoneNumber: phoneResult.value, photoUrl: photoUrl,
    ));
  }
}