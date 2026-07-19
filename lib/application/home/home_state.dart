import 'package:fixgo/domain/category/service_category.dart';
import 'package:fixgo/domain/request/service_request.dart';
import 'package:fixgo/domain/technician/technician_profile.dart';

sealed class HomeState {
  const HomeState();

  R when<R>({
    required R Function() loading,
    required R Function(HomeLoaded state) loaded,
    required R Function(String message) error,
  }) {
    if (this is HomeLoading) {
      return loading();
    } else if (this is HomeLoaded) {
      return loaded(this as HomeLoaded);
    } else {
      return error((this as HomeError).message);
    }
  }
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  const HomeLoaded({
    this.categories = const [],
    this.nearbyRequests = const [],
    this.topTechnicians = const [],
    this.isLoadingRequests = false,
    this.isLoadingTechnicians = false,
  });

  final List<ServiceCategory> categories;
  final List<ServiceRequest> nearbyRequests;
  final List<TechnicianProfile> topTechnicians;
  final bool isLoadingRequests;
  final bool isLoadingTechnicians;
}

class HomeError extends HomeState {
  const HomeError(this.message);
  final String message;
}