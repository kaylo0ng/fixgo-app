import 'package:fixgo/domain/core/enums/service_request_status.dart';
import 'package:fixgo/domain/core/result.dart';
import 'package:fixgo/domain/core/entity.dart';
import 'package:fixgo/domain/core/value_objects.dart';

class ServiceRequest extends Entity<ServiceRequest> implements Validatable {
  const ServiceRequest({
    required this.id, required this.clientId, required this.categoryId,
    required this.title, required this.description, required this.address,
    required this.coordinates, required this.status, required this.createdAt,
    this.updatedAt, this.selectedOfferId, this.scheduledAt, this.completedAt,
    this.cancelledAt, this.cancellationReason, this.estimatedPrice,
  });

  @override final String id;
  final String clientId;
  final ServiceCategoryId categoryId;
  final NonEmptyString title;
  final String description;
  final String address;
  final Coordinates coordinates;
  final ServiceRequestStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? selectedOfferId;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final Price? estimatedPrice;

  @override bool get isValid => validationErrors.isEmpty;

  @override List<ValueFailure> get validationErrors {
    final errors = <ValueFailure>[];
    if (description.trim().isEmpty) errors.add(EmptyString(description));
    if (address.trim().isEmpty) errors.add(EmptyString(address));
    if (estimatedPrice != null && estimatedPrice!.value < 0) errors.add(NegativePrice(estimatedPrice!.value.toString()));
    return errors;
  }

  bool get isOpen => status == ServiceRequestStatus.published || status == ServiceRequestStatus.receivingOffers;
  bool get isInProgress => status == ServiceRequestStatus.technicianSelected || status == ServiceRequestStatus.inProgress;
  bool get isFinished => status == ServiceRequestStatus.completed || status == ServiceRequestStatus.rated || status == ServiceRequestStatus.cancelled;

  bool get canReceiveOffers => status == ServiceRequestStatus.published || status == ServiceRequestStatus.receivingOffers;
  bool get canBeAssigned => status == ServiceRequestStatus.receivingOffers;
  bool get canBeStarted => status == ServiceRequestStatus.technicianSelected;
  bool get canBeCompleted => status == ServiceRequestStatus.inProgress;
  bool get canBeRated => status == ServiceRequestStatus.completed;
  bool get canBeCancelled => status == ServiceRequestStatus.published || status == ServiceRequestStatus.receivingOffers || status == ServiceRequestStatus.technicianSelected;

  ServiceRequest publish() {
    if (status != ServiceRequestStatus.published) throw StateError('Solo solicitudes pendientes pueden publicarse');
    return copyWith(status: ServiceRequestStatus.published, updatedAt: DateTime.now());
  }

  ServiceRequest startReceivingOffers() {
    if (status != ServiceRequestStatus.published) throw StateError('Solo solicitudes publicadas pueden recibir ofertas');
    return copyWith(status: ServiceRequestStatus.receivingOffers, updatedAt: DateTime.now());
  }

  ServiceRequest assignTechnician(String offerId) {
    if (!canBeAssigned) throw StateError('La solicitud no puede ser asignada');
    return copyWith(status: ServiceRequestStatus.technicianSelected, selectedOfferId: offerId, updatedAt: DateTime.now());
  }

  ServiceRequest startService() {
    if (!canBeStarted) throw StateError('El servicio no puede iniciarse');
    return copyWith(status: ServiceRequestStatus.inProgress, updatedAt: DateTime.now());
  }

  ServiceRequest completeService() {
    if (!canBeCompleted) throw StateError('El servicio no puede completarse');
    return copyWith(status: ServiceRequestStatus.completed, completedAt: DateTime.now(), updatedAt: DateTime.now());
  }

  ServiceRequest rate() {
    if (!canBeRated) throw StateError('El servicio no puede ser calificado');
    return copyWith(status: ServiceRequestStatus.rated, updatedAt: DateTime.now());
  }

  ServiceRequest cancel({required String reason}) {
    if (!canBeCancelled) throw StateError('La solicitud no puede cancelarse');
    if (reason.trim().isEmpty) throw ArgumentError('Se requiere un motivo');
    return copyWith(status: ServiceRequestStatus.cancelled, cancelledAt: DateTime.now(), cancellationReason: reason, updatedAt: DateTime.now());
  }

  ServiceRequest copyWith({
    String? id, String? clientId, ServiceCategoryId? categoryId, NonEmptyString? title,
    String? description, String? address, Coordinates? coordinates, ServiceRequestStatus? status,
    DateTime? createdAt, DateTime? updatedAt, String? selectedOfferId, DateTime? scheduledAt,
    DateTime? completedAt, DateTime? cancelledAt, Price? estimatedPrice, String? cancellationReason,
  }) {
    return ServiceRequest(
      id: id ?? this.id, clientId: clientId ?? this.clientId, categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title, description: description ?? this.description, address: address ?? this.address,
      coordinates: coordinates ?? this.coordinates, status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
      selectedOfferId: selectedOfferId ?? this.selectedOfferId, scheduledAt: scheduledAt ?? this.scheduledAt,
      completedAt: completedAt ?? this.completedAt, cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason, estimatedPrice: estimatedPrice ?? this.estimatedPrice,
    );
  }

  static Result<ServiceRequest> create({
    required String id, required String clientId, required String categoryId,
    required String title, required String description, required String address,
    required double latitude, required double longitude, Price? estimatedPrice,
  }) {
    final titleResult = NonEmptyString.create(title, maxLength: 100);
    final catResult = ServiceCategoryId.create(categoryId);
    final coordsResult = Coordinates.create(latitude, longitude);

    if (description.trim().isEmpty) return Result.err(EmptyString(description));
    if (address.trim().isEmpty) return Result.err(EmptyString(address));
    if (estimatedPrice != null && estimatedPrice.value < 0) return Result.err(NegativePrice(estimatedPrice.value.toString()));

    return switch ((titleResult, catResult, coordsResult)) {
      (Ok(value: final t), Ok(value: final c), Ok(value: final coords)) =>
        Ok(ServiceRequest(id: id, clientId: clientId, categoryId: c, title: t,
            description: description, address: address, coordinates: coords,
            status: ServiceRequestStatus.published, createdAt: DateTime.now(), estimatedPrice: estimatedPrice)),
      (Err(failure: final f), _, _) => Err(f),
      (_, Err(failure: final f), _) => Err(f),
      (_, _, Err(failure: final f)) => Err(f),
    };
  }
}
