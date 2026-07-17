import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fixgo/core/domain/enums/user_role.dart';
import 'package:fixgo/domain/core/result.dart';
import 'package:fixgo/domain/core/value_objects.dart';
import 'package:fixgo/domain/user/app_user.dart';
import 'package:fixgo/domain/user/repositories.dart';
import 'package:fixgo/application/user/app_user_state.dart';
import 'package:fixgo/application/providers/repositories.dart';

final appUserViewModelProvider = StateNotifierProvider<AppUserViewModel, AppUserState>(AppUserViewModel.new);

class AppUserViewModel extends StateNotifier<AppUserState> {
  AppUserViewModel(this.ref) : super(const AppUserState());

  final Ref ref;

  Future<Result<AppUser>> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    final repo = ref.read(userRepositoryProvider);

    final emailResult = Email.create(email);
    if (emailResult.isErr) {
      state = state.copyWith(isSubmitting: false, error: emailResult.failure.message);
      return Result.err(emailResult.failure);
    }

    final userResult = await repo.getByEmail(emailResult.value);

    return userResult.fold(
      (user) {
        if (user == null) {
          state = state.copyWith(isSubmitting: false, error: 'Usuario no encontrado');
          return Result.err(NotFoundFailure('Usuario', email));
        }
        state = state.copyWith(currentUser: user, isSubmitting: false);
        return Result.ok(user);
      },
      (failure) {
        state = state.copyWith(isSubmitting: false, error: failure.message);
        return Result.err(failure);
      },
    );
  }

  Future<Result<AppUser>> register({
    required String id,
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    final repo = ref.read(userRepositoryProvider);

    final emailResult = Email.create(email);
    if (emailResult.isErr) {
      state = state.copyWith(isSubmitting: false, error: emailResult.failure.message);
      return Result.err(emailResult.failure);
    }

    final existingResult = await repo.getByEmail(emailResult.value);
    if (existingResult.isOk && existingResult.value != null) {
      state = state.copyWith(isSubmitting: false, error: 'El email ya está registrado');
      return Result.err(ValidationFailure([EmptyString('email')]));
    }

    final userRole = role == 'technician' ? UserRole.technician : UserRole.client;

    final createResult = AppUser.create(
      id: id,
      fullName: fullName,
      email: email,
      role: userRole,
      phoneNumber: phoneNumber,
    );

    if (createResult.isErr) {
      state = state.copyWith(isSubmitting: false, error: createResult.failure.message);
      return Result.err(createResult.failure);
    }

    final saveResult = await repo.create(createResult.value);

    saveResult.fold(
      (saved) => state = state.copyWith(currentUser: saved, isSubmitting: false, successMessage: 'Registro exitoso'),
      (failure) => state = state.copyWith(isSubmitting: false, error: failure.message),
    );

    return saveResult;
  }

  Future<void> loadCurrentUser(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    final repo = ref.read(userRepositoryProvider);
    final result = await repo.getById(UserId.create(userId).value!);

    result.fold(
      (user) => state = state.copyWith(currentUser: user, isLoading: false),
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearSuccess() {
    state = state.copyWith(successMessage: null);
  }
}