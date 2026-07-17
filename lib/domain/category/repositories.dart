import 'package:fixgo/domain/category/service_category.dart';
import 'package:fixgo/domain/core/result.dart';
import 'package:fixgo/domain/core/value_objects.dart';

abstract interface class ICategoryRepository {
  Future<Result<List<ServiceCategory>>> getAll({bool onlyActive = true});

  Future<Result<ServiceCategory>> getById(ServiceCategoryId id);

  Future<Result<ServiceCategory>> create(ServiceCategory category);
}