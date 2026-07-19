import 'package:fixgo/domain/technician/technician_profile.dart';
import 'package:fixgo/domain/rating/rating.dart';

sealed class TechnicianState {
  const TechnicianState();

  R when<R>({
    required R Function() loading,
    required R Function(TechnicianLoaded state) loaded,
    required R Function(String message) error,
  }) {
    if (this is TechnicianLoading) {
      return loading();
    } else if (this is TechnicianLoaded) {
      return loaded(this as TechnicianLoaded);
    } else {
      return error((this as TechnicianError).message);
    }
  }

  TechnicianState copyWith({
    TechnicianProfile? profile,
    List<Rating>? ratings,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    String? successMessage,
  }) {
    if (this is TechnicianLoaded) {
      final loaded = this as TechnicianLoaded;
      return TechnicianLoaded(
        profile: profile ?? loaded.profile,
        ratings: ratings ?? loaded.ratings,
        isLoading: isLoading ?? loaded.isLoading,
        isSubmitting: isSubmitting ?? loaded.isSubmitting,
        error: error ?? loaded.error,
        successMessage: successMessage ?? loaded.successMessage,
      );
    }
    return this;
  }
}

class TechnicianLoading extends TechnicianState {
  const TechnicianLoading();
}

class TechnicianLoaded extends TechnicianState {
  const TechnicianLoaded({
    this.profile,
    this.ratings = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.successMessage,
  });

  final TechnicianProfile? profile;
  final List<Rating> ratings;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final String? successMessage;
}

class TechnicianError extends TechnicianState {
  const TechnicianError(this.message);
  final String message;
}