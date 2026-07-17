import 'package:fixgo/domain/technician/technician_profile.dart';
import 'package:fixgo/domain/rating/rating.dart';

class TechnicianState {
  const TechnicianState({
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

  TechnicianState copyWith({
    TechnicianProfile? profile,
    List<Rating>? ratings,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    String? successMessage,
  }) {
    return TechnicianState(
      profile: profile ?? this.profile,
      ratings: ratings ?? this.ratings,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}