import 'package:fixgo/domain/core/result.dart';
import 'package:fixgo/domain/core/entity.dart';
import 'package:fixgo/domain/core/value_objects.dart';

class Offer extends Entity<Offer> implements Validatable {
  const Offer({
    required this.id, required this.requestId, required this.technicianId,
    required this.proposedPrice, required this.estimatedDuration,
    required this.message, required this.status, required this.createdAt,
    this.updatedAt, this.acceptedAt, this.rejectedAt,
  });

  @override final String id;
  final String requestId;
  final String technicianId;
  final Price proposedPrice;
  final DurationMinutes estimatedDuration;
  final String message;
  final OfferStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;

  @override bool get isValid => validationErrors.isEmpty;

  @override List<ValueFailure> get validationErrors {
    final errors = <ValueFailure>[];
    if (message.trim().isEmpty) errors.add(EmptyString(message));
    if (proposedPrice.value <= 0) errors.add(NegativePrice(proposedPrice.value.toString()));
    if (estimatedDuration.value <= 0) errors.add(InvalidDuration(estimatedDuration.value.toString()));
    return errors;
  }

  bool get isPending => status == OfferStatus.pending;
  bool get isAccepted => status == OfferStatus.accepted;
  bool get isRejected => status == OfferStatus.rejected;
  bool get isWithdrawn => status == OfferStatus.withdrawn;

  bool get canBeAccepted => status == OfferStatus.pending;
  bool get canBeRejected => status == OfferStatus.pending;
  bool get canBeWithdrawn => status == OfferStatus.pending;

  Offer accept() {
    if (!canBeAccepted) throw StateError('La oferta no puede ser aceptada');
    return copyWith(status: OfferStatus.accepted, acceptedAt: DateTime.now(), updatedAt: DateTime.now());
  }

  Offer reject() {
    if (!canBeRejected) throw StateError('La oferta no puede ser rechazada');
    return copyWith(status: OfferStatus.rejected, rejectedAt: DateTime.now(), updatedAt: DateTime.now());
  }

  Offer withdraw() {
    if (!canBeWithdrawn) throw StateError('La oferta no puede ser retirada');
    return copyWith(status: OfferStatus.withdrawn, updatedAt: DateTime.now());
  }

  Offer copyWith({
    String? id, String? requestId, String? technicianId, Price? proposedPrice,
    DurationMinutes? estimatedDuration, String? message, OfferStatus? status,
    DateTime? createdAt, DateTime? updatedAt, DateTime? acceptedAt, DateTime? rejectedAt,
  }) {
    return Offer(
      id: id ?? this.id, requestId: requestId ?? this.requestId,
      technicianId: technicianId ?? this.technicianId,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      message: message ?? this.message, status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt, rejectedAt: rejectedAt ?? this.rejectedAt,
    );
  }

  static Result<Offer> create({
    required String id, required String requestId, required String technicianId,
    required double price, required int durationMinutes, required String message,
  }) {
    final priceResult = Price.create(price);
    final durResult = DurationMinutes.create(durationMinutes);

    if (priceResult.isErr) return Result.err(priceResult.failure);
    if (durResult.isErr) return Result.err(durResult.failure);

    return Result.ok(Offer(
      id: id, requestId: requestId, technicianId: technicianId,
      proposedPrice: priceResult.value, estimatedDuration: durResult.value,
      message: message, status: OfferStatus.pending, createdAt: DateTime.now(),
    ));
  }
}

enum OfferStatus { pending, accepted, rejected, withdrawn, expired }