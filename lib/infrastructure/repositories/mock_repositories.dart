import 'package:fixgo/domain/core/result.dart';
import 'package:fixgo/domain/category/service_category.dart';
import 'package:fixgo/domain/request/service_request.dart';
import 'package:fixgo/domain/request/offer.dart';
import 'package:fixgo/domain/technician/technician_profile.dart';
import 'package:fixgo/domain/rating/rating.dart';
import 'package:fixgo/domain/user/app_user.dart';
import 'package:fixgo/domain/core/value_objects.dart';
import 'package:fixgo/domain/request/repositories.dart';
import 'package:fixgo/domain/technician/repositories.dart';
import 'package:fixgo/domain/rating/rating.dart' as rating_domain;
import 'package:fixgo/domain/user/repositories.dart' as user_domain;
import 'package:fixgo/domain/category/repositories.dart' as category_domain;
import 'package:fixgo/core/domain/enums/service_request_status.dart';

class MockServiceRequestRepository implements IServiceRequestRepository {
  final Map<String, ServiceRequest> _requests = {};

  @override
  Future<Result<ServiceRequest>> getById(RequestId id) async {
    final request = _requests[id.value];
    if (request == null) return Result.err(NotFoundFailure('ServiceRequest', id.value));
    return Result.ok(request);
  }

  @override
  Future<Result<List<ServiceRequest>>> getByClientId(UserId clientId) async {
    final requests = _requests.values.where((r) => r.clientId == clientId.value).toList();
    return Result.ok(requests);
  }

  @override
  Future<Result<List<ServiceRequest>>> getByTechnicianId(String technicianId) async {
    final requests = _requests.values.where((r) => r.selectedOfferId != null && r.selectedOfferId!.contains(technicianId)).toList();
    return Result.ok(requests);
  }

  @override
  Future<Result<List<ServiceRequest>>> getOpenRequests({
    ServiceCategoryId? categoryId,
    double? maxDistanceKm,
    Coordinates? location,
    ServiceRequestStatus? status,
  }) async {
    var requests = _requests.values.where((r) =>
      r.status == ServiceRequestStatus.published ||
      r.status == ServiceRequestStatus.receivingOffers ||
      r.status == ServiceRequestStatus.technicianSelected
    ).toList();

    if (categoryId != null) {
      requests = requests.where((r) => r.categoryId.value == categoryId.value).toList();
    }

    return Result.ok(requests);
  }

  @override
  Future<Result<ServiceRequest>> create(ServiceRequest request) async {
    _requests[request.id] = request;
    return Result.ok(request);
  }

  @override
  Future<Result<ServiceRequest>> update(ServiceRequest request) async {
    if (!_requests.containsKey(request.id)) {
      return Result.err(NotFoundFailure('ServiceRequest', request.id));
    }
    _requests[request.id] = request;
    return Result.ok(request);
  }

  @override
  Future<Result<void>> delete(RequestId id) async {
    _requests.remove(id.value);
    return Result.ok(null);
  }

  @override
  Future<Result<List<ServiceRequest>>> search({
    String? query,
    ServiceCategoryId? categoryId,
    ServiceRequestStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var requests = _requests.values.toList();

    if (query != null && query.isNotEmpty) {
      requests = requests.where((r) =>
        r.title.value.toLowerCase().contains(query.toLowerCase()) ||
        r.description.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }

    if (categoryId != null) {
      requests = requests.where((r) => r.categoryId.value == categoryId.value).toList();
    }

    if (status != null) {
      requests = requests.where((r) => r.status == status).toList();
    }

    if (fromDate != null) {
      requests = requests.where((r) => r.createdAt.isAfter(fromDate!)).toList();
    }

    if (toDate != null) {
      requests = requests.where((r) => r.createdAt.isBefore(toDate!)).toList();
    }

    return Result.ok(requests);
  }
}

class MockOfferRepository implements IOfferRepository {
  final Map<String, Offer> _offers = {};

  @override
  Future<Result<Offer>> getById(String id) async {
    final offer = _offers[id];
    if (offer == null) return Result.err(NotFoundFailure('Offer', id));
    return Result.ok(offer);
  }

  @override
  Future<Result<List<Offer>>> getByRequestId(String requestId) async {
    final offers = _offers.values.where((o) => o.requestId == requestId).toList();
    return Result.ok(offers);
  }

  @override
  Future<Result<List<Offer>>> getByTechnicianId(String technicianId) async {
    final offers = _offers.values.where((o) => o.technicianId == technicianId).toList();
    return Result.ok(offers);
  }

  @override
  Future<Result<Offer>> create(Offer offer) async {
    _offers[offer.id] = offer;
    return Result.ok(offer);
  }

  @override
  Future<Result<Offer>> update(Offer offer) async {
    if (!_offers.containsKey(offer.id)) {
      return Result.err(NotFoundFailure('Offer', offer.id));
    }
    _offers[offer.id] = offer;
    return Result.ok(offer);
  }

  @override
  Future<Result<void>> delete(String id) async {
    _offers.remove(id);
    return Result.ok(null);
  }
}

class MockTechnicianProfileRepository implements ITechnicianProfileRepository {
  final Map<String, TechnicianProfile> _profiles = {};
  final Map<String, TechnicianProfile> _profilesByUserId = {};

  @override
  Future<Result<TechnicianProfile>> getById(TechnicianId id) async {
    final profile = _profiles[id.value];
    if (profile == null) return Result.err(NotFoundFailure('TechnicianProfile', id.value));
    return Result.ok(profile);
  }

  @override
  Future<Result<TechnicianProfile>> getByUserId(UserId userId) async {
    final profile = _profilesByUserId[userId.value];
    if (profile == null) return Result.err(NotFoundFailure('TechnicianProfile', userId.value));
    return Result.ok(profile);
  }

  @override
  Future<Result<TechnicianProfile>> create(TechnicianProfile profile) async {
    _profiles[profile.id] = profile;
    _profilesByUserId[profile.userId] = profile;
    return Result.ok(profile);
  }

  @override
  Future<Result<TechnicianProfile>> update(TechnicianProfile profile) async {
    if (!_profiles.containsKey(profile.id)) {
      return Result.err(NotFoundFailure('TechnicianProfile', profile.id));
    }
    _profiles[profile.id] = profile;
    _profilesByUserId[profile.userId] = profile;
    return Result.ok(profile);
  }

  @override
  Future<Result<List<TechnicianProfile>>> getByCategory(ServiceCategoryId categoryId) async {
    final profiles = _profiles.values.where((p) => p.categoryIds.any((c) => c.value == categoryId.value)).toList();
    return Result.ok(profiles);
  }

  @override
  Future<Result<List<TechnicianProfile>>> getNearby({
    required Coordinates location,
    required double radiusKm,
    ServiceCategoryId? categoryId,
    bool onlyVerified = true,
  }) async {
    var profiles = _profiles.values.toList();

    if (onlyVerified) {
      profiles = profiles.where((p) => p.isVerified).toList();
    }

    if (categoryId != null) {
      profiles = profiles.where((p) => p.categoryIds.any((c) => c.value == categoryId.value)).toList();
    }

    profiles = profiles.where((p) => p.distanceTo(location) <= radiusKm).toList();

    return Result.ok(profiles);
  }

  @override
  Future<Result<List<TechnicianProfile>>> getTopRated({
    required int limit,
    ServiceCategoryId? categoryId,
  }) async {
    var profiles = _profiles.values.where((p) => p.averageRating != null).toList();

    if (categoryId != null) {
      profiles = profiles.where((p) => p.categoryIds.any((c) => c.value == categoryId.value)).toList();
    }

    profiles.sort((a, b) => (b.averageRating?.value ?? 0).compareTo(a.averageRating?.value ?? 0));

    return Result.ok(profiles.take(limit).toList());
  }
}

class MockRatingRepository implements IRatingRepository {
  final Map<String, Rating> _ratings = {};

  @override
  Future<Result<Rating>> getById(String id) async {
    final rating = _ratings[id];
    if (rating == null) return Result.err(NotFoundFailure('Rating', id));
    return Result.ok(rating);
  }

  @override
  Future<Result<List<Rating>>> getByTechnicianId(String technicianId) async {
    final ratings = _ratings.values.where((r) => r.technicianId == technicianId).toList();
    return Result.ok(ratings);
  }

  @override
  Future<Result<List<Rating>>> getByClientId(String clientId) async {
    final ratings = _ratings.values.where((r) => r.clientId == clientId).toList();
    return Result.ok(ratings);
  }

  @override
  Future<Result<Rating>> create(Rating rating) async {
    _ratings[rating.id] = rating;
    return Result.ok(rating);
  }

  @override
  Future<Result<double>> getAverageRating(String technicianId) async {
    final ratings = _ratings.values.where((r) => r.technicianId == technicianId).toList();
    if (ratings.isEmpty) return Result.ok(0.0);

    final sum = ratings.fold<double>(0.0, (acc, r) => acc + r.score.value);
    return Result.ok(sum / ratings.length);
  }
}

class MockUserRepository implements user_domain.IUserRepository {
  final Map<String, AppUser> _users = {};
  final Map<String, AppUser> _usersByEmail = {};

  @override
  Future<Result<AppUser>> getById(UserId id) async {
    final user = _users[id.value];
    if (user == null) return Result.err(NotFoundFailure('AppUser', id.value));
    return Result.ok(user);
  }

  @override
  Future<Result<AppUser?>> getByEmail(Email email) async {
    final user = _usersByEmail[email.value];
    if (user == null) return Result.ok(null);
    return Result.ok(user);
  }

  @override
  Future<Result<AppUser>> create(AppUser user) async {
    _users[user.id] = user;
    _usersByEmail[user.email.value] = user;
    return Result.ok(user);
  }

  @override
  Future<Result<AppUser>> update(AppUser user) async {
    if (!_users.containsKey(user.id)) {
      return Result.err(NotFoundFailure('AppUser', user.id));
    }
    _users[user.id] = user;
    _usersByEmail[user.email.value] = user;
    return Result.ok(user);
  }

  @override
  Future<Result<void>> delete(UserId id) async {
    final user = _users.remove(id.value);
    if (user != null) _usersByEmail.remove(user.email.value);
    return Result.ok(null);
  }
}

class MockCategoryRepository implements category_domain.ICategoryRepository {
  final Map<String, ServiceCategory> _categories = {};

  MockCategoryRepository() {
    _initCategories();
  }

  void _initCategories() {
    final categoriesData = [
      ('plumbing', 'Plomería', 'plumbing', 'Servicios de plomería y tuberías'),
      ('electrical', 'Electricidad', 'electrical_services', 'Servicios eléctricos e instalaciones'),
      ('carpentry', 'Carpintería', 'carpentry', 'Trabajos de carpintería y madera'),
      ('painting', 'Pintura', 'format_paint', 'Pintura interior y exterior'),
      ('hvac', 'Climatización', 'ac_unit', 'Aire acondicionado y calefacción'),
      ('appliance_repair', 'Reparación de electrodomésticos', 'kitchen', 'Reparación de electrodomésticos del hogar'),
      ('cleaning', 'Limpieza', 'cleaning_services', 'Servicios de limpieza profesional'),
      ('gardening', 'Jardinería', 'yard', 'Mantenimiento de jardines y áreas verdes'),
      ('masonry', 'Albañilería', 'construction', 'Trabajos de albañilería y construcción'),
      ('roofing', 'Techos e impermeabilización', 'roofing', 'Instalación y reparación de techos'),
    ];

    for (final (id, name, icon, desc) in categoriesData) {
      final result = ServiceCategory.create(
        id: id,
        name: name,
        iconName: icon,
        description: desc,
      );
      if (result.isOk) {
        _categories[id] = result.value!;
      }
    }
  }

  @override
  Future<Result<List<ServiceCategory>>> getAll({bool onlyActive = true}) async {
    var categories = _categories.values.toList();
    if (onlyActive) {
      categories = categories.where((c) => c.isActive).toList();
    }
    return Result.ok(categories);
  }

  @override
  Future<Result<ServiceCategory>> getById(ServiceCategoryId id) async {
    final category = _categories[id.value];
    if (category == null) return Result.err(NotFoundFailure('ServiceCategory', id.value));
    return Result.ok(category);
  }

  @override
  Future<Result<ServiceCategory>> create(ServiceCategory category) async {
    _categories[category.id] = category;
    return Result.ok(category);
  }
}