import 'package:fixgo/domain/core/result.dart';

abstract class Entity<T extends Entity<T>> {
  const Entity();
  String get id;

  @override
  bool operator ==(Object other) => other is Entity && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$runtimeType(id: $id)';
}

abstract class Validatable {
  bool get isValid;
  List<ValueFailure> get validationErrors;
}

mixin ValidationMixin on Validatable {
  Result<Unit> validate() {
    final errors = validationErrors;
    if (errors.isEmpty) return Result.ok(Unit.unit);
    return Result.err(ValidationFailure(errors));
  }
}

class Unit {
  const Unit();
  static const unit = Unit();
  @override bool operator ==(Object other) => other is Unit;
  @override int get hashCode => 0;
  @override String toString() => 'Unit';
}