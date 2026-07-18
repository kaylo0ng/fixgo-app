import 'package:fixgo/domain/core/value_objects.dart';
import 'package:fixgo/domain/request/service_request.dart';
import 'package:fixgo/domain/request/offer.dart';
import 'package:fixgo/domain/technician/technician_profile.dart';
import 'package:fixgo/domain/rating/rating.dart';
import 'package:fixgo/domain/user/app_user.dart';
import 'package:fixgo/domain/category/service_category.dart';
import 'package:fixgo/domain/core/enums/service_request_status.dart';
import 'package:fixgo/domain/core/enums/user_role.dart';

class DTOMapper {
  static Map<String, dynamic> serviceCategoryToJson(ServiceCategory category) {
    return {
      'id': category.id,
      'name': category.name.value,
      'iconName': category.iconName,
      'description': category.description,
      'isActive': category.isActive,
      'parentId': category.parentId,
      'sortOrder': category.sortOrder,
    };
  }

  static ServiceCategory serviceCategoryFromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] as String,
      name: NonEmptyString.create(json['name'] as String).value!,
      iconName: json['iconName'] as String,
      description: json['description'] as String,
      isActive: json['isActive'] as bool? ?? true,
      parentId: json['parentId'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  static Map<String, dynamic> coordinatesToJson(Coordinates coords) {
    return {
      'latitude': coords.latitude,
      'longitude': coords.longitude,
    };
  }

  static Coordinates coordinatesFromJson(Map<String, dynamic> json) {
    return Coordinates.create(
      json['latitude'] as double,
      json['longitude'] as double,
    ).value!;
  }

  static Map<String, dynamic> serviceRequestToJson(ServiceRequest request) {
    return {
      'id': request.id,
      'clientId': request.clientId,
      'categoryId': request.categoryId.value,
      'title': request.title.value,
      'description': request.description,
      'address': request.address,
      'coordinates': coordinatesToJson(request.coordinates),
      'status': request.status.name,
      'createdAt': request.createdAt.toIso8601String(),
      'updatedAt': request.updatedAt?.toIso8601String(),
      'selectedOfferId': request.selectedOfferId,
      'scheduledAt': request.scheduledAt?.toIso8601String(),
      'completedAt': request.completedAt?.toIso8601String(),
      'cancelledAt': request.cancelledAt?.toIso8601String(),
      'cancellationReason': request.cancellationReason,
      'estimatedPrice': request.estimatedPrice?.value,
    };
  }

  static ServiceRequest serviceRequestFromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      categoryId: ServiceCategoryId.create(json['categoryId'] as String).value!,
      title: NonEmptyString.create(json['title'] as String).value!,
      description: json['description'] as String,
      address: json['address'] as String,
      coordinates: coordinatesFromJson(json['coordinates'] as Map<String, dynamic>),
      status: ServiceRequestStatus.values.firstWhere((s) => s.name == json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      selectedOfferId: json['selectedOfferId'] as String?,
      scheduledAt: json['scheduledAt'] != null ? DateTime.parse(json['scheduledAt'] as String) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt'] as String) : null,
      cancellationReason: json['cancellationReason'] as String?,
      estimatedPrice: json['estimatedPrice'] != null ? Price(json['estimatedPrice'] as double) : null,
    );
  }

  static Map<String, dynamic> offerToJson(Offer offer) {
    return {
      'id': offer.id,
      'requestId': offer.requestId,
      'technicianId': offer.technicianId,
      'proposedPrice': offer.proposedPrice.value,
      'estimatedDuration': offer.estimatedDuration.value,
      'message': offer.message,
      'status': offer.status.name,
      'createdAt': offer.createdAt.toIso8601String(),
      'updatedAt': offer.updatedAt?.toIso8601String(),
      'acceptedAt': offer.acceptedAt?.toIso8601String(),
      'rejectedAt': offer.rejectedAt?.toIso8601String(),
    };
  }

  static Offer offerFromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] as String,
      requestId: json['requestId'] as String,
      technicianId: json['technicianId'] as String,
      proposedPrice: Price(json['proposedPrice'] as double),
      estimatedDuration: DurationMinutes(json['estimatedDuration'] as int),
      message: json['message'] as String,
      status: OfferStatus.values.firstWhere((s) => s.name == json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt'] as String) : null,
      rejectedAt: json['rejectedAt'] != null ? DateTime.parse(json['rejectedAt'] as String) : null,
    );
  }

  static Map<String, dynamic> technicianProfileToJson(TechnicianProfile profile) {
    return {
      'id': profile.id,
      'userId': profile.userId,
      'bio': profile.bio.value,
      'categoryIds': profile.categoryIds.map((c) => c.value).toList(),
      'coordinates': coordinatesToJson(profile.serviceArea),
      'averageRating': profile.averageRating?.value,
      'completedServices': profile.completedServices,
      'isVerified': profile.isVerified,
      'hourlyRate': profile.hourlyRate?.value,
      'availabilityRadiusKm': profile.availabilityRadiusKm,
      'createdAt': profile.createdAt?.toIso8601String(),
      'updatedAt': profile.updatedAt?.toIso8601String(),
    };
  }

  static TechnicianProfile technicianProfileFromJson(Map<String, dynamic> json) {
    return TechnicianProfile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      bio: NonEmptyString.create(json['bio'] as String).value!,
      categoryIds: (json['categoryIds'] as List).map((c) => ServiceCategoryId.create(c as String).value!).toList(),
      serviceArea: coordinatesFromJson(json['coordinates'] as Map<String, dynamic>),
      averageRating: json['averageRating'] != null ? RatingValue(json['averageRating'] as double) : null,
      completedServices: json['completedServices'] as int,
      isVerified: json['isVerified'] as bool,
      hourlyRate: json['hourlyRate'] != null ? Price(json['hourlyRate'] as double) : null,
      availabilityRadiusKm: json['availabilityRadiusKm'] as int,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  static Map<String, dynamic> ratingToJson(Rating rating) {
    return {
      'id': rating.id,
      'requestId': rating.requestId,
      'clientId': rating.clientId,
      'technicianId': rating.technicianId,
      'score': rating.score.value,
      'comment': rating.comment,
      'categories': rating.categories.map((k, v) => MapEntry(k, v.value)),
      'createdAt': rating.createdAt.toIso8601String(),
    };
  }

  static Rating ratingFromJson(Map<String, dynamic> json) {
    final categoriesJson = json['categories'] as Map<String, dynamic>;
    return Rating(
      id: json['id'] as String,
      requestId: json['requestId'] as String,
      clientId: json['clientId'] as String,
      technicianId: json['technicianId'] as String,
      score: RatingValue(json['score'] as double),
      comment: json['comment'] as String,
      categories: categoriesJson.map((k, v) => MapEntry(k, RatingValue(v as double))),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static Map<String, dynamic> appUserToJson(AppUser user) {
    return {
      'id': user.id,
      'fullName': user.fullName.value,
      'email': user.email.value,
      'role': user.role.name,
      'createdAt': user.createdAt.toIso8601String(),
      'phoneNumber': user.phoneNumber?.value,
      'photoUrl': user.photoUrl,
      'isActive': user.isActive,
    };
  }

  static AppUser appUserFromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      fullName: NonEmptyString.create(json['fullName'] as String).value!,
      email: Email.create(json['email'] as String).value!,
      role: UserRole.values.firstWhere((r) => r.name == json['role']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      phoneNumber: json['phoneNumber'] != null ? PhoneNumber.create(json['phoneNumber'] as String).value : null,
      photoUrl: json['photoUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
