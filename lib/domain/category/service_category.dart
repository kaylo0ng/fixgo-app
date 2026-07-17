import 'package:fixgo/domain/core/result.dart';
import 'package:fixgo/domain/core/entity.dart';
import 'package:fixgo/domain/core/value_objects.dart';

class ServiceCategory extends Entity<ServiceCategory> implements Validatable {
  const ServiceCategory({
    required this.id, required this.name, required this.iconName,
    required this.description, this.isActive = true, this.parentId,
    this.sortOrder = 0,
  });

  @override final String id;
  final NonEmptyString name;
  final String iconName;
  final String description;
  final bool isActive;
  final String? parentId;
  final int sortOrder;

  @override bool get isValid => validationErrors.isEmpty;

  @override List<ValueFailure> get validationErrors {
    final errors = <ValueFailure>[];
    if (name.value.trim().isEmpty) errors.add(EmptyString(name.value));
    if (description.trim().isEmpty) errors.add(EmptyString(description));
    return errors;
  }

  ServiceCategory copyWith({
    String? id, NonEmptyString? name, String? iconName,
    String? description, bool? isActive, String? parentId, int? sortOrder,
  }) {
    return ServiceCategory(
      id: id ?? this.id, name: name ?? this.name, iconName: iconName ?? this.iconName,
      description: description ?? this.description, isActive: isActive ?? this.isActive,
      parentId: parentId ?? this.parentId, sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  static Result<ServiceCategory> create({
    required String id, required String name, required String iconName,
    required String description, bool isActive = true, String? parentId,
    int sortOrder = 0,
  }) {
    final Result<ServiceCategoryId> idResult = ServiceCategoryId.create(id);
    final Result<NonEmptyString> nameResult = NonEmptyString.create(name, maxLength: 50);
    final Result<String?> parentResult = parentId != null && parentId.isNotEmpty
        ? ServiceCategoryId.create(parentId).map((v) => v.value)
        : Result.ok<String?>(null);

    if (idResult.isErr) return Result.err(idResult.failure);
    if (nameResult.isErr) return Result.err(nameResult.failure);
    if (parentResult.isErr) return Result.err(parentResult.failure);

    return Result.ok(ServiceCategory(
      id: idResult.value.value, name: nameResult.value, iconName: iconName,
      description: description, isActive: isActive, parentId: parentResult.value, sortOrder: sortOrder,
    ));
  }
}