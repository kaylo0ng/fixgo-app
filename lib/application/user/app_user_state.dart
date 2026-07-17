import 'package:fixgo/domain/user/app_user.dart';

class AppUserState {
  const AppUserState({
    this.currentUser,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.successMessage,
  });

  final AppUser? currentUser;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final String? successMessage;

  AppUserState copyWith({
    AppUser? currentUser,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    String? successMessage,
  }) {
    return AppUserState(
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}