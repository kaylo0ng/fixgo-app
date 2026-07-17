import 'package:fixgo/domain/core/result.dart';
import 'package:fixgo/domain/technician/technician_profile.dart';
import 'package:fixgo/domain/rating/rating.dart';
import 'package:fixgo/domain/user/app_user.dart';
import 'package:fixgo/domain/category/service_category.dart';
import 'package:fixgo/domain/core/value_objects.dart';

abstract interface class ITechnicianProfileRepository {
  Future<Result<TechnicianProfile>> getById(TechnicianId id);
  Future<Result<TechnicianProfile>> getByUserId(UserId userId);
  Future<Result<TechnicianProfile>> create(TechnicianProfile profile);
  Future<Result<TechnicianProfile>> update(TechnicianProfile profile);
  Future<Result<List<TechnicianProfile>>> getByCategory(ServiceCategoryId categoryId);
  Future<Result<List<TechnicianProfile>>> getNearby({
    required Coordinates location, required double radiusKm,
    ServiceCategoryId? categoryId, bool onlyVerified = true,
  });
}

abstract interface class IRatingRepository {
  Future<Result<Rating>> getById(String id);
  Future<Result<List<Rating>>> getByTechnicianId(String technicianId);
  Future<Result<List<Rating>>> getByClientId(String clientId);
  Future<Result<Rating>> create(Rating rating);
  Future<Result<double>> getAverageRating(String technicianId);
}

abstract interface class IUserRepository {
  Future<Result<AppUser>> getById(UserId id);
  Future<Result<AppUser>> getByEmail(Email email);
  Future<Result<AppUser>> create(AppUser user);
  Future<Result<AppUser>> update(AppUser user);
  Future<Result<void>> delete(UserId id);
}

abstract interface class ICategoryRepository {
  Future<Result<List<ServiceCategory>>> getAll({bool onlyActive = true});
  Future<Result<ServiceCategory>> getById(ServiceCategoryId id);
  Future<Result<ServiceCategory>> create(ServiceCategory category);
}