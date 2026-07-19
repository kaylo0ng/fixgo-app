import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixgo/domain/core/result.dart';
import 'package:fixgo/domain/technician/technician_profile.dart';
import 'package:fixgo/domain/technician/repositories.dart';
import 'package:fixgo/domain/rating/rating.dart';
import 'package:fixgo/infrastructure/models/mappers.dart';
import 'package:fixgo/domain/core/enums/service_request_status.dart';
import 'package:fixgo/domain/core/value_objects.dart';
import 'package:fixgo/domain/user/app_user.dart';
import 'package:fixgo/domain/user/repositories.dart' as user_domain;
import 'package:fixgo/domain/category/service_category.dart';
import 'package:fixgo/domain/category/repositories.dart' as category_domain;
import 'package:fixgo/domain/core/value_objects.dart';
import 'package:fixgo/domain/core/enums/user_role.dart';

class FirestoreTechnicianProfileRepository implements ITechnicianProfileRepository {
  final CollectionReference<Map<String, dynamic>> _col = FirebaseFirestore.instance.collection('technician_profiles');

  @override
  Future<Result<TechnicianProfile>> getById(TechnicianId id) async {
    try {
      final doc = await _col.doc(id.value).get();
      if (!doc.exists) return Result.err(NotFoundFailure('TechnicianProfile', id.value));
      return Result.ok(DTOMapper.technicianProfileFromJson(doc.data()!));
    } catch (e) {
      return Result.err(RepositoryFailure('Error al obtener perfil: $e'));
    }
  }

  @override
  Future<Result<TechnicianProfile>> getByUserId(UserId userId) async {
    try {
      final snapshot = await _col.where('userId', isEqualTo: userId.value).limit(1).get();
      if (snapshot.docs.isEmpty) return Result.err(NotFoundFailure('TechnicianProfile', userId.value));
      return Result.ok(DTOMapper.technicianProfileFromJson(snapshot.docs.first.data()));
    } catch (e) {
      return Result.err(RepositoryFailure('Error al obtener perfil por usuario: $e'));
    }
  }

  @override
  Future<Result<TechnicianProfile>> create(TechnicianProfile profile) async {
    try {
      final data = DTOMapper.technicianProfileToJson(profile);
      await _col.doc(profile.id).set(data);
      return Result.ok(profile);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al crear perfil: $e'));
    }
  }

  @override
  Future<Result<TechnicianProfile>> update(TechnicianProfile profile) async {
    try {
      final data = DTOMapper.technicianProfileToJson(profile);
      await _col.doc(profile.id).update(data);
      return Result.ok(profile);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al actualizar perfil: $e'));
    }
  }

  @override
  Future<Result<List<TechnicianProfile>>> getByCategory(ServiceCategoryId categoryId) async {
    try {
      final snapshot = await _col.where('categoryIds', arrayContains: categoryId.value).get();
      final profiles = snapshot.docs.map((doc) => DTOMapper.technicianProfileFromJson(doc.data())).toList();
      return Result.ok(profiles);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al obtener perfiles por categoría: $e'));
    }
  }

  @override
  Future<Result<List<TechnicianProfile>>> getNearby({
    required Coordinates location,
    required double radiusKm,
    ServiceCategoryId? categoryId,
    bool onlyVerified = true,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _col.where('isVerified', isEqualTo: true);
      
      if (categoryId != null) {
        query = query.where('categoryIds', arrayContains: categoryId.value);
      }

      final snapshot = await query.get();
      var profiles = snapshot.docs.map((doc) => DTOMapper.technicianProfileFromJson(doc.data())).toList();

      profiles = profiles.where((p) => p.distanceTo(location) <= radiusKm).toList();

      return Result.ok(profiles);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al buscar técnicos cercanos: $e'));
    }
  }

  @override
  Future<Result<List<TechnicianProfile>>> getTopRated({
    required int limit,
    ServiceCategoryId? categoryId,
  }) async {
    try {
      var query = _col.where('isVerified', isEqualTo: true).where('averageRating', isNotEqualTo: null);
      
      if (categoryId != null) {
        query = query.where('categoryIds', arrayContains: categoryId.value);
      }

      final snapshot = await query.get();
      var profiles = snapshot.docs.map((doc) => DTOMapper.technicianProfileFromJson(doc.data())).toList();

      profiles = profiles.where((p) => p.averageRating != null).toList();
      profiles.sort((a, b) => (b.averageRating!.value).compareTo(a.averageRating!.value));

      if (profiles.length > limit) {
        profiles = profiles.take(limit).toList();
      }

      return Result.ok(profiles);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al obtener top técnicos: $e'));
    }
  }
}

class FirestoreRatingRepository implements IRatingRepository {
  final CollectionReference<Map<String, dynamic>> _col = FirebaseFirestore.instance.collection('ratings');

  @override
  Future<Result<Rating>> getById(String id) async {
    try {
      final doc = await _col.doc(id).get();
      if (!doc.exists) return Result.err(NotFoundFailure('Rating', id));
      return Result.ok(DTOMapper.ratingFromJson(doc.data()!));
    } catch (e) {
      return Result.err(RepositoryFailure('Error al obtener calificación: $e'));
    }
  }

  @override
  Future<Result<List<Rating>>> getByTechnicianId(String technicianId) async {
    try {
      final snapshot = await _col.where('technicianId', isEqualTo: technicianId).get();
      final ratings = snapshot.docs.map((doc) => DTOMapper.ratingFromJson(doc.data())).toList();
      return Result.ok(ratings);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al obtener calificaciones del técnico: $e'));
    }
  }

  @override
  Future<Result<List<Rating>>> getByClientId(String clientId) async {
    try {
      final snapshot = await _col.where('clientId', isEqualTo: clientId).get();
      final ratings = snapshot.docs.map((doc) => DTOMapper.ratingFromJson(doc.data())).toList();
      return Result.ok(ratings);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al obtener calificaciones del cliente: $e'));
    }
  }

  @override
  Future<Result<Rating>> create(Rating rating) async {
    try {
      final data = DTOMapper.ratingToJson(rating);
      await _col.doc(rating.id).set(data);
      return Result.ok(rating);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al crear calificación: $e'));
    }
  }

  @override
  Future<Result<Rating>> update(Rating rating) async {
    try {
      final data = DTOMapper.ratingToJson(rating);
      await _col.doc(rating.id).update(data);
      return Result.ok(rating);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al actualizar calificación: $e'));
    }
  }

  @override
  Future<Result<double>> getAverageRating(String technicianId) async {
    try {
      final snapshot = await _col.where('technicianId', isEqualTo: technicianId).get();
      if (snapshot.docs.isEmpty) return Result.ok(0.0);
      
      final ratings = snapshot.docs.map((doc) => DTOMapper.ratingFromJson(doc.data())).toList();
      final sum = ratings.fold<double>(0, (acc, r) => acc + r.score.value);
      return Result.ok(sum / ratings.length);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al calcular promedio: $e'));
    }
  }
}

class FirestoreUserRepository implements user_domain.IUserRepository {
  final CollectionReference<Map<String, dynamic>> _col = FirebaseFirestore.instance.collection('users');

  @override
  Future<Result<AppUser>> getById(UserId id) async {
    try {
      final doc = await _col.doc(id.value).get();
      if (!doc.exists) return Result.err(NotFoundFailure('AppUser', id.value));
      return Result.ok(DTOMapper.appUserFromJson(doc.data()!));
    } catch (e) {
      return Result.err(RepositoryFailure('Error al obtener usuario: $e'));
    }
  }

  @override
  Future<Result<AppUser?>> getByEmail(Email email) async {
    try {
      final snapshot = await _col.where('email', isEqualTo: email.value).limit(1).get();
      if (snapshot.docs.isEmpty) return Result.ok(null);
      return Result.ok(DTOMapper.appUserFromJson(snapshot.docs.first.data()));
    } catch (e) {
      return Result.err(RepositoryFailure('Error al obtener usuario por email: $e'));
    }
  }

  @override
  Future<Result<AppUser>> create(AppUser user) async {
    try {
      final data = DTOMapper.appUserToJson(user);
      await _col.doc(user.id).set(data);
      return Result.ok(user);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al crear usuario: $e'));
    }
  }

  @override
  Future<Result<AppUser>> update(AppUser user) async {
    try {
      final data = DTOMapper.appUserToJson(user);
      await _col.doc(user.id).update(data);
      return Result.ok(user);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al actualizar usuario: $e'));
    }
  }

  @override
  Future<Result<void>> delete(UserId id) async {
    try {
      await _col.doc(id.value).delete();
      return Result.ok(null);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al eliminar usuario: $e'));
    }
  }
}

class FirestoreCategoryRepository implements category_domain.ICategoryRepository {
  final CollectionReference<Map<String, dynamic>> _col = FirebaseFirestore.instance.collection('categories');

  @override
  Future<Result<List<ServiceCategory>>> getAll({bool onlyActive = true}) async {
    try {
      var query = _col as Query<Map<String, dynamic>>;
      if (onlyActive) query = query.where('isActive', isEqualTo: true);
      
      final snapshot = await query.get();
      final categories = snapshot.docs.map((doc) => DTOMapper.serviceCategoryFromJson(doc.data())).toList();
      return Result.ok(categories);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al obtener categorías: $e'));
    }
  }

  @override
  Future<Result<ServiceCategory>> getById(ServiceCategoryId id) async {
    try {
      final doc = await _col.doc(id.value).get();
      if (!doc.exists) return Result.err(NotFoundFailure('ServiceCategory', id.value));
      return Result.ok(DTOMapper.serviceCategoryFromJson(doc.data()!));
    } catch (e) {
      return Result.err(RepositoryFailure('Error al obtener categoría: $e'));
    }
  }

  @override
  Future<Result<ServiceCategory>> create(ServiceCategory category) async {
    try {
      final data = DTOMapper.serviceCategoryToJson(category);
      await _col.doc(category.id).set(data);
      return Result.ok(category);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al crear categoría: $e'));
    }
  }

  @override
  Future<Result<ServiceCategory>> update(ServiceCategory category) async {
    try {
      final data = DTOMapper.serviceCategoryToJson(category);
      await _col.doc(category.id).update(data);
      return Result.ok(category);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al actualizar categoría: $e'));
    }
  }

  @override
  Future<Result<void>> delete(ServiceCategoryId id) async {
    try {
      await _col.doc(id.value).delete();
      return Result.ok(null);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al eliminar categoría: $e'));
    }
  }
}