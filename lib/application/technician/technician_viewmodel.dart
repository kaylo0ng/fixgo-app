import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fixgo/domain/core/result.dart';
import 'package:fixgo/domain/technician/technician_profile.dart';
import 'package:fixgo/domain/technician/repositories.dart';
import 'package:fixgo/domain/rating/rating.dart';
import 'package:fixgo/application/technician/technician_state.dart';
import 'package:fixgo/application/providers/repositories.dart';

final technicianViewModelProvider = NotifierProvider<TechnicianViewModel, TechnicianState>(TechnicianViewModel.new);

class TechnicianViewModel extends Notifier<TechnicianState> {
  @override
  TechnicianState build() {
    return const TechnicianState();
  }

  Future<void> loadProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    final repo = ref.read(technicianProfileRepositoryProvider);
    final result = await repo.getByUserId(userId);

    result.fold(
      (profile) => state = state.copyWith(profile: profile, isLoading: false),
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
    );
  }

  Future<Result<TechnicianProfile>> createProfile({
    required String id,
    required String userId,
    required String bio,
    required List<String> categoryIds,
    required double latitude,
    required double longitude,
    double? hourlyRate,
    int availabilityRadiusKm = 20,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null, successMessage: null);
    final repo = ref.read(technicianProfileRepositoryProvider);

    final createResult = TechnicianProfile.create(
      id: id,
      userId: userId,
      bio: bio,
      categoryIds: categoryIds,
      latitude: latitude,
      longitude: longitude,
      hourlyRate: hourlyRate != null ? Price(hourlyRate) : null,
      availabilityRadiusKm: availabilityRadiusKm,
    );

    if (createResult.isErr) {
      state = state.copyWith(isSubmitting: false, error: createResult.failure.message);
      return Result.err(createResult.failure);
    }

    final saveResult = await repo.create(createResult.value);

    saveResult.fold(
      (saved) {
        state = state.copyWith(
          profile: saved,
          isSubmitting: false,
          successMessage: 'Perfil de técnico creado correctamente',
        );
      },
      (failure) => state = state.copyWith(isSubmitting: false, error: failure.message),
    );

    return saveResult;
  }

  Future<void> updateProfile(TechnicianProfile updated) async {
    state = state.copyWith(isSubmitting: true, error: null);
    final repo = ref.read(technicianProfileRepositoryProvider);
    final result = await repo.update(updated);

    result.fold(
      (saved) => state = state.copyWith(profile: saved, isSubmitting: false, successMessage: 'Perfil actualizado'),
      (failure) => state = state.copyWith(isSubmitting: false, error: failure.message),
    );
  }

  Future<void> loadRatings(String technicianId) async {
    state = state.copyWith(isLoading: true, error: null);
    final repo = ref.read(ratingRepositoryProvider);
    final result = await repo.getByTechnicianId(technicianId);

    result.fold(
      (ratings) => state = state.copyWith(ratings: ratings, isLoading: false),
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