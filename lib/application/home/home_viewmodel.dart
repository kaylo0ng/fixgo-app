import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fixgo/domain/core/value_objects.dart';
import 'package:fixgo/application/home/home_state.dart';
import 'package:fixgo/application/providers/repositories.dart';
import 'package:fixgo/domain/category/service_category.dart';
import 'package:fixgo/domain/request/service_request.dart';
import 'package:fixgo/domain/technician/technician_profile.dart';

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);

class HomeViewModel extends StateNotifier<HomeState> {
  HomeViewModel(this.ref) : super(const HomeLoading());

  final Ref ref;

  Future<void> loadCategories() async {
    state = const HomeLoading();
    final repo = ref.read(categoryRepositoryProvider);
    final result = await repo.getAll();

    result.fold(
      (categories) => state = HomeLoaded(categories: categories),
      (failure) => state = HomeError(failure.message),
    );
  }

  Future<void> loadNearbyRequests({
    required Coordinates location,
    double radiusKm = 10,
  }) async {
    final currentState = state;
    final currentCategories = currentState is HomeLoaded ? currentState.categories : <ServiceCategory>[];
    final currentTopTechs = currentState is HomeLoaded ? currentState.topTechnicians : <TechnicianProfile>[];

    state = HomeLoaded(
      categories: currentCategories,
      nearbyRequests: [],
      topTechnicians: currentTopTechs,
      isLoadingRequests: true,
    );

    final repo = ref.read(serviceRequestRepositoryProvider);
    final result = await repo.getOpenRequests(
      location: location,
      maxDistanceKm: radiusKm,
    );

    result.fold(
      (requests) => state = HomeLoaded(
        categories: currentState is HomeLoaded ? currentState.categories : <ServiceCategory>[],
        nearbyRequests: requests,
        topTechnicians: currentState is HomeLoaded ? currentState.topTechnicians : <TechnicianProfile>[],
      ),
      (failure) => state = HomeError(failure.message),
    );
  }

  Future<void> loadTopTechnicians({
    ServiceCategoryId? categoryId,
    int limit = 5,
  }) async {
    final currentState = state;
    final currentCategories = currentState is HomeLoaded ? currentState.categories : <ServiceCategory>[];
    final currentNearby = currentState is HomeLoaded ? currentState.nearbyRequests : <ServiceRequest>[];

    state = HomeLoaded(
      categories: currentCategories,
      nearbyRequests: currentNearby,
      topTechnicians: [],
      isLoadingTechnicians: true,
    );

    final repo = ref.read(technicianProfileRepositoryProvider);
    final result = await repo.getTopRated(limit: limit, categoryId: categoryId);

    result.fold(
      (technicians) => state = HomeLoaded(
        categories: currentCategories,
        nearbyRequests: currentNearby,
        topTechnicians: technicians,
      ),
      (failure) => state = HomeError(failure.message),
    );
  }

  void clearError() {
    final currentState = state;
    if (currentState is HomeError) {
      state = HomeLoaded(
        categories: <ServiceCategory>[],
        nearbyRequests: <ServiceRequest>[],
        topTechnicians: <TechnicianProfile>[],
      );
    }
  }
}