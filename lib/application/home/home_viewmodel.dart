import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fixgo/domain/core/result.dart';
import 'package:fixgo/domain/category/service_category.dart';
import 'package:fixgo/domain/request/service_request.dart';
import 'package:fixgo/domain/technician/technician_profile.dart';
import 'package:fixgo/domain/core/value_objects.dart';
import 'package:fixgo/application/home/home_state.dart';
import 'package:fixgo/application/providers/repositories.dart';

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);

class HomeViewModel extends StateNotifier<HomeState> {
  HomeViewModel(this.ref) : super(const HomeState());

  final Ref ref;

  Future<void> loadCategories() async {
    state = state.copyWith(isLoadingCategories: true, error: null);
    final repo = ref.read(categoryRepositoryProvider);
    final result = await repo.getAll();

    result.fold(
      (categories) => state = state.copyWith(categories: categories, isLoadingCategories: false),
      (failure) => state = state.copyWith(isLoadingCategories: false, error: failure.message),
    );
  }

  Future<void> loadNearbyRequests({
    required Coordinates location,
    double radiusKm = 10,
  }) async {
    state = state.copyWith(isLoadingRequests: true, error: null);
    final repo = ref.read(serviceRequestRepositoryProvider);
    final result = await repo.getOpenRequests(
      location: location,
      maxDistanceKm: radiusKm,
    );

    result.fold(
      (requests) => state = state.copyWith(nearbyRequests: requests, isLoadingRequests: false),
      (failure) => state = state.copyWith(isLoadingRequests: false, error: failure.message),
    );
  }

  Future<void> loadTopTechnicians({
    ServiceCategoryId? categoryId,
    int limit = 5,
  }) async {
    state = state.copyWith(isLoadingTechnicians: true, error: null);
    final repo = ref.read(technicianProfileRepositoryProvider);
    final result = await repo.getTopRated(limit: limit, categoryId: categoryId);

    result.fold(
      (technicians) => state = state.copyWith(topTechnicians: technicians, isLoadingTechnicians: false),
      (failure) => state = state.copyWith(isLoadingTechnicians: false, error: failure.message),
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}