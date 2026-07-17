import 'package:fixgo/domain/request/service_request.dart';
import 'package:fixgo/domain/request/offer.dart';

class ServiceRequestState {
  const ServiceRequestState({
    this.requests = const [],
    this.openRequests = const [],
    this.selectedRequest,
    this.offers = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.successMessage,
  });

  final List<ServiceRequest> requests;
  final List<ServiceRequest> openRequests;
  final ServiceRequest? selectedRequest;
  final List<Offer> offers;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final String? successMessage;

  ServiceRequestState copyWith({
    List<ServiceRequest>? requests,
    List<ServiceRequest>? openRequests,
    ServiceRequest? selectedRequest,
    List<Offer>? offers,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    String? successMessage,
  }) {
    return ServiceRequestState(
      requests: requests ?? this.requests,
      openRequests: openRequests ?? this.openRequests,
      selectedRequest: selectedRequest ?? this.selectedRequest,
      offers: offers ?? this.offers,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}