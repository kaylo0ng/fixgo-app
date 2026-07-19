import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fixgo/domain/core/result.dart';
import 'package:fixgo/domain/core/value_objects.dart';
import 'package:fixgo/domain/request/service_request.dart';
import 'package:fixgo/domain/request/offer.dart';
import 'package:fixgo/domain/request/repositories.dart';
import 'package:fixgo/application/service_request/service_request_state.dart';
import 'package:fixgo/application/providers/repositories.dart';

final serviceRequestViewModelProvider = StateNotifierProvider<ServiceRequestViewModel, ServiceRequestState>(ServiceRequestViewModel.new);

class ServiceRequestViewModel extends StateNotifier<ServiceRequestState> {
  ServiceRequestViewModel(this.ref) : super(const ServiceRequestLoading());

  final Ref ref;

  Future<void> loadMyRequests(String clientId) async {
    state = const ServiceRequestLoading();
    final repo = ref.read(serviceRequestRepositoryProvider);
    final result = await repo.getByClientId(UserId.create(clientId).getOrThrow());

    result.fold(
      (requests) => state = ServiceRequestLoaded(requests: requests),
      (failure) => state = ServiceRequestError(failure.message),
    );
  }

  Future<void> loadOpenRequests({
    String? categoryId,
    double? latitude,
    double? longitude,
    double? maxDistanceKm,
  }) async {
    state = const ServiceRequestLoading();
    final repo = ref.read(serviceRequestRepositoryProvider);
    final result = await repo.getOpenRequests(
      categoryId: categoryId != null ? ServiceCategoryId.create(categoryId).getOrThrow() : null,
      maxDistanceKm: maxDistanceKm,
      location: latitude != null && longitude != null
          ? Coordinates.create(latitude!, longitude!).getOrThrow()
          : null,
    );

    result.fold(
      (requests) => state = ServiceRequestLoaded(openRequests: requests),
      (failure) => state = ServiceRequestError(failure.message),
    );
  }

  Future<Result<ServiceRequest>> createRequest({
    required String id,
    required String clientId,
    required String categoryId,
    required String title,
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    double? estimatedPrice,
  }) async {
    state = const ServiceRequestLoading();
    final repo = ref.read(serviceRequestRepositoryProvider);

    final createResult = ServiceRequest.create(
      id: id,
      clientId: clientId,
      categoryId: categoryId,
      title: title,
      description: description,
      address: address,
      latitude: latitude,
      longitude: longitude,
      estimatedPrice: estimatedPrice != null ? Price(estimatedPrice) : null,
    );

    if (createResult.isErr) {
      state = ServiceRequestError(createResult.failure.message);
      return Result.err(createResult.failure);
    }

    final saveResult = await repo.create(createResult.getOrThrow());

    saveResult.fold(
      (saved) {
        state = ServiceRequestLoaded(
          requests: [saved],
          openRequests: [saved],
          isSubmitting: false,
          successMessage: 'Solicitud creada correctamente',
        );
      },
      (failure) => state = ServiceRequestError(failure.message),
    );

    return saveResult;
  }

  Future<void> publishRequest(String requestId) async {
    final repo = ref.read(serviceRequestRepositoryProvider);
    final getResult = await repo.getById(RequestId.create(requestId).getOrThrow());

    await getResult.fold(
      (request) async {
        final published = request.publish();
        final saveResult = await repo.update(published);
        saveResult.fold(
          (saved) {
            state = ServiceRequestLoaded(
              requests: [saved],
              openRequests: [saved],
            );
          },
          (failure) => state = ServiceRequestError(failure.message),
        );
      },
      (failure) => state = ServiceRequestError(failure.message),
    );
  }

  Future<void> loadRequestOffers(String requestId) async {
    state = const ServiceRequestLoading();
    final repo = ref.read(offerRepositoryProvider);
    final result = await repo.getByRequestId(requestId);

    result.fold(
      (offers) => state = ServiceRequestLoaded(offers: offers),
      (failure) => state = ServiceRequestError(failure.message),
    );
  }

  Future<void> submitOffer({
    required String id,
    required String requestId,
    required String technicianId,
    required double price,
    required int durationMinutes,
    required String message,
  }) async {
    state = const ServiceRequestLoading();
    final repo = ref.read(offerRepositoryProvider);

    final createResult = Offer.create(
      id: id,
      requestId: requestId,
      technicianId: technicianId,
      price: price,
      durationMinutes: durationMinutes,
      message: message,
    );

    if (createResult.isErr) {
      state = ServiceRequestError(createResult.failure.message);
      return;
    }

    final saveResult = await repo.create(createResult.getOrThrow());

    saveResult.fold(
      (saved) {
        state = ServiceRequestLoaded(
          offers: [saved],
          isSubmitting: false,
          successMessage: 'Oferta enviada correctamente',
        );
      },
      (failure) => state = ServiceRequestError(failure.message),
    );
  }

  Future<void> acceptOffer(String offerId, String requestId) async {
    final offerRepo = ref.read(offerRepositoryProvider);
    final requestRepo = ref.read(serviceRequestRepositoryProvider);

    final offerResult = await offerRepo.getById(offerId);
    await offerResult.fold(
      (offer) async {
        final accepted = offer.accept();
        final saveOfferResult = await offerRepo.update(accepted);

        await saveOfferResult.fold(
          (savedOffer) async {
            final requestResult = await ref.read(serviceRequestRepositoryProvider).getById(RequestId.create(requestId).getOrThrow());
            requestResult.fold(
              (request) async {
                final updated = request.assignTechnician(offerId);
                final saveRequestResult = await requestRepo.update(updated);
                saveRequestResult.fold(
                  (savedRequest) {
                    state = ServiceRequestLoaded(
                      selectedRequest: savedRequest,
                    );
                  },
                  (failure) => state = ServiceRequestError(failure.message),
                );
              },
              (failure) => state = ServiceRequestError(failure.message),
            );
          },
          (failure) => state = ServiceRequestError(failure.message),
        );
      },
      (failure) => state = ServiceRequestError(failure.message),
    );
  }

  void clearError() {
    state = const ServiceRequestLoaded();
  }

  void clearSuccess() {
    state = const ServiceRequestLoaded();
  }
}