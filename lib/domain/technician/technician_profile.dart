import 'package:fixgo/domain/core/result.dart';
import 'package:fixgo/domain/core/entity.dart';
import 'package:fixgo/domain/core/value_objects.dart';

class TechnicianProfile extends Entity<TechnicianProfile> implements Validatable {
  const TechnicianProfile({
    required this.id, required this.userId, required this.bio,
    required this.categoryIds, required this.serviceArea,
    required this.averageRating, required this.completedServices,
    required this.isVerified, this.hourlyRate, this.availabilityRadiusKm = 20,
    this.createdAt, this.updatedAt,
  });

  @override final String id;
  final String userId;
  final NonEmptyString bio;
  final List<ServiceCategoryId> categoryIds;
  final Coordinates serviceArea;
  final RatingValue? averageRating;
  final int completedServices;
  final bool isVerified;
  final Price? hourlyRate;
  final int availabilityRadiusKm;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override bool get isValid => validationErrors.isEmpty;

  @override List<ValueFailure> get validationErrors {
    final errors = <ValueFailure>[];
    if (categoryIds.isEmpty) errors.add(EmptyString('categories'));
    if (hourlyRate != null && hourlyRate!.value < 0) errors.add(NegativePrice(hourlyRate!.value.toString()));
    if (availabilityRadiusKm <= 0 || availabilityRadiusKm > 100) errors.add(InvalidDuration(availabilityRadiusKm.toString()));
    return errors;
  }

  bool get canAcceptRequests => isVerified && categoryIds.isNotEmpty;
  bool hasCategory(ServiceCategoryId cat) => categoryIds.contains(cat);
  double distanceTo(Coordinates loc) => serviceArea.distanceTo(loc);
  bool isAvailableFor(Coordinates reqLoc) => distanceTo(reqLoc) <= availabilityRadiusKm;

  TechnicianProfile copyWith({
    String? id, String? userId, NonEmptyString? bio, List<ServiceCategoryId>? categoryIds,
    Coordinates? serviceArea, RatingValue? averageRating, int? completedServices,
    bool? isVerified, Price? hourlyRate, int? availabilityRadiusKm,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return TechnicianProfile(
      id: id ?? this.id, userId: userId ?? this.userId, bio: bio ?? this.bio,
      categoryIds: categoryIds ?? this.categoryIds, serviceArea: serviceArea ?? this.serviceArea,
      averageRating: averageRating ?? this.averageRating, completedServices: completedServices ?? this.completedServices,
      isVerified: isVerified ?? this.isVerified, hourlyRate: hourlyRate ?? this.hourlyRate,
      availabilityRadiusKm: availabilityRadiusKm ?? this.availabilityRadiusKm,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  static Result<TechnicianProfile> create({
    required String id, required String userId, required String bio,
    required List<String> categoryIds, required double latitude, required double longitude,
    Price? hourlyRate, int availabilityRadiusKm = 20,
  }) {
    final bioResult = NonEmptyString.create(bio, maxLength: 500);
    final Result<Price?> rateResult = hourlyRate != null ? Price.create(hourlyRate.value) : Result.ok<Price?>(null);
    final catResults = <Result<ServiceCategoryId>>[];
    for (final c in categoryIds) {
      catResults.add(ServiceCategoryId.create(c));
    }
    final coordsResult = Coordinates.create(latitude, longitude);

    for (final Result<ServiceCategoryId> r in catResults) {
      if (r.isErr) return Result.err(r.failure);
    }

    if (bioResult.isErr) return Result.err(bioResult.failure);
    if (rateResult.isErr) return Result.err(rateResult.failure);
    if (coordsResult.isErr) return Result.err(coordsResult.failure);

    return Result.ok(TechnicianProfile(
      id: id, userId: userId, bio: bioResult.value,
      categoryIds: catResults.map((r) => r.value).toList(),
      serviceArea: coordsResult.value, averageRating: null, completedServices: 0,
      isVerified: false, hourlyRate: rateResult.value, availabilityRadiusKm: availabilityRadiusKm,
      createdAt: DateTime.now(),
    ));
  }
}