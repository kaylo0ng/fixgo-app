import 'package:fixgo/domain/category/service_category.dart';
import 'package:fixgo/domain/request/service_request.dart';
import 'package:fixgo/domain/technician/technician_profile.dart';

class HomeState {
  const HomeState({
    this.categories = const [],
    this.nearbyRequests = const [],
    this.topTechnicians = const [],
    this.isLoadingCategories = false,
    this.isLoadingRequests = false,
    this.isLoadingTechnicians = false,
    this.error,
  });

  final List<ServiceCategory> categories;
  final List<ServiceRequest> nearbyRequests;
  final List<TechnicianProfile> topTechnicians;
  final bool isLoadingCategories;
  final bool isLoadingRequests;
  final bool isLoadingTechnicians;
  final String? error;

  HomeState copyWith({
    List<ServiceCategory>? categories,
    List<ServiceRequest>? nearbyRequests,
    List<TechnicianProfile>? topTechnicians,
    bool? isLoadingCategories,
    bool? isLoadingRequests,
    bool? isLoadingTechnicians,
    String? error,
  }) {
    return HomeState(
      categories: categories ?? this.categories,
      nearbyRequests: nearbyRequests ?? this.nearbyRequests,
      topTechnicians: topTechnicians ?? this.topTechnicians,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      isLoadingRequests: isLoadingRequests ?? this.isLoadingRequests,
      isLoadingTechnicians: isLoadingTechnicians ?? this.isLoadingTechnicians,
      error: error ?? this.error,
    );
  }
}