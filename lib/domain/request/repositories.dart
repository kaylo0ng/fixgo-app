import 'package:fixgo/domain/core/result.dart';
import 'package:fixgo/domain/request/service_request.dart';
import 'package:fixgo/domain/request/offer.dart';
import 'package:fixgo/domain/core/enums/service_request_status.dart';
import 'package:fixgo/domain/core/value_objects.dart';

abstract interface class IServiceRequestRepository {
  Future<Result<ServiceRequest>> getById(RequestId id);
  Future<Result<List<ServiceRequest>>> getByClientId(UserId clientId);
  Future<Result<List<ServiceRequest>>> getByTechnicianId(String technicianId);
  Future<Result<List<ServiceRequest>>> getOpenRequests({
    ServiceCategoryId? categoryId, double? maxDistanceKm,
    Coordinates? location, ServiceRequestStatus? status,
  });
  Future<Result<ServiceRequest>> create(ServiceRequest request);
  Future<Result<ServiceRequest>> update(ServiceRequest request);
  Future<Result<void>> delete(RequestId id);
  Future<Result<List<ServiceRequest>>> search({
    String? query, ServiceCategoryId? categoryId,
    ServiceRequestStatus? status, DateTime? fromDate, DateTime? toDate,
  });
}

abstract interface class IOfferRepository {
  Future<Result<Offer>> getById(String id);
  Future<Result<List<Offer>>> getByRequestId(String requestId);
  Future<Result<List<Offer>>> getByTechnicianId(String technicianId);
  Future<Result<Offer>> create(Offer offer);
  Future<Result<Offer>> update(Offer offer);
  Future<Result<void>> delete(String id);
}
