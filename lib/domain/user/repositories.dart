import 'package:fixgo/domain/user/app_user.dart';
import 'package:fixgo/domain/core/result.dart';
import 'package:fixgo/domain/core/value_objects.dart';

abstract interface class IUserRepository {
  Future<Result<AppUser>> getById(UserId id);

  Future<Result<AppUser>> getByEmail(Email email);

  Future<Result<AppUser>> create(AppUser user);

  Future<Result<AppUser>> update(AppUser user);

  Future<Result<void>> delete(UserId id);
}