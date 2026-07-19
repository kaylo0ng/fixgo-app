import 'package:fixgo/domain/request/service_request.dart';
import 'package:fixgo/domain/request/offer.dart';

sealed class ServiceRequestState {
  const ServiceRequestState();

  R when<R>({
    required R Function() loading,
    required R Function(ServiceRequestLoaded state) loaded,
    required R Function(String message) error,
  }) {
    if (this is ServiceRequestLoading) {
      return loading();
    } else if (this is ServiceRequestLoaded) {
      return loaded(this as ServiceRequestLoaded);
    } else {
      return error((this as ServiceRequestError).message);
    }
  }

  ServiceRequestState copyWith({
    List<ServiceRequest>? requests,
    List<ServiceRequest>? openRequests,
    List<Offer>? offers,
    ServiceRequest? selectedRequest,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    String? successMessage,
  }) {
    if (this is ServiceRequestLoaded) {
      final loaded = this as ServiceRequestLoaded;
      return ServiceRequestLoaded(
        requests: requests ?? loaded.requests,
        openRequests: openRequests ?? loaded.openRequests,
        offers: offers ?? loaded.offers,
        selectedRequest: selectedRequest ?? loaded.selectedRequest,
        isLoading: isLoading ?? loaded.isLoading,
        isSubmitting: isSubmitting ?? loaded.isSubmitting,
        error: error ?? loaded.error,
        successMessage: successMessage ?? loaded.successMessage,
      );
    }
    return this;
  }
}

class ServiceRequestLoading extends ServiceRequestState {
  const ServiceRequestLoading();
}

class ServiceRequestLoaded extends ServiceRequestState {
  const ServiceRequestLoaded({
    this.requests = const [],
    this.openRequests = const [],
    this.offers = const [],
    this.selectedRequest,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.successMessage,
  });

  final List<ServiceRequest> requests;
  final List<ServiceRequest> openRequests;
  final List<Offer> offers;
  final ServiceRequest? selectedRequest;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final String? successMessage;
}

class ServiceRequestError extends ServiceRequestState {
  const ServiceRequestError(this.message);
  final String message;
}