import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixgo/domain/core/result.dart';
import 'package:fixgo/domain/core/value_objects.dart';
import 'package:fixgo/domain/request/service_request.dart';
import 'package:fixgo/domain/request/offer.dart';
import 'package:fixgo/domain/request/repositories.dart';
import 'package:fixgo/domain/core/enums/service_request_status.dart';
import 'package:fixgo/infrastructure/models/mappers.dart';

class FirestoreServiceRequestRepository implements IServiceRequestRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'service_requests';

  FirestoreServiceRequestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _firestore.collection(_collection);

  @override
  Future<Result<ServiceRequest>> getById(RequestId id) async {
    try {
      final doc = await _col.doc(id.value).get();
      if (!doc.exists) {
        return Result.err(NotFoundFailure('ServiceRequest', id.value));
      }
      return Result.ok(DTOMapper.serviceRequestFromJson(doc.data()!));
    } catch (e) {
      return Result.err(RepositoryFailure('Error al obtener solicitud: $e'));
    }
  }

  @override
  Future<Result<List<ServiceRequest>>> getByClientId(UserId clientId) async {
    try {
      final query = await _col.where('clientId', isEqualTo: clientId.value).get();
      final requests = query.docs.map((doc) => DTOMapper.serviceRequestFromJson(doc.data())).toList();
      return Result.ok(requests);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al obtener solicitudes del cliente: $e'));
    }
  }

  @override
  Future<Result<List<ServiceRequest>>> getByTechnicianId(String technicianId) async {
    try {
      final query = await _col.where('selectedOfferId', isEqualTo: technicianId).get();
      final requests = query.docs.map((doc) => DTOMapper.serviceRequestFromJson(doc.data())).toList();
      return Result.ok(requests);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al obtener solicitudes del técnico: $e'));
    }
  }

  @override
  Future<Result<List<ServiceRequest>>> getOpenRequests({
    ServiceCategoryId? categoryId,
    double? maxDistanceKm,
    Coordinates? location,
    ServiceRequestStatus? status,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _col.where('status', whereIn: [
        ServiceRequestStatus.published.name,
        ServiceRequestStatus.receivingOffers.name,
        ServiceRequestStatus.technicianSelected.name,
      ]);

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId.value);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.get();
      var requests = snapshot.docs.map((doc) => DTOMapper.serviceRequestFromJson(doc.data())).toList();

      if (location != null && maxDistanceKm != null) {
        requests = requests.where((r) => r.coordinates.distanceTo(location!) <= maxDistanceKm!).toList();
      }

      return Result.ok(requests);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al obtener solicitudes abiertas: $e'));
    }
  }

  @override
  Future<Result<ServiceRequest>> create(ServiceRequest request) async {
    try {
      final data = DTOMapper.serviceRequestToJson(request);
      await _col.doc(request.id).set(data);
      return Result.ok(request);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al crear solicitud: $e'));
    }
  }

  @override
  Future<Result<ServiceRequest>> update(ServiceRequest request) async {
    try {
      final data = DTOMapper.serviceRequestToJson(request);
      await _col.doc(request.id).update(data);
      return Result.ok(request);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al actualizar solicitud: $e'));
    }
  }

  @override
  Future<Result<void>> delete(RequestId id) async {
    try {
      await _col.doc(id.value).delete();
      return Result.ok(null);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al eliminar solicitud: $e'));
    }
  }

  @override
  Future<Result<List<ServiceRequest>>> search({
    String? query,
    ServiceCategoryId? categoryId,
    ServiceRequestStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      Query<Map<String, dynamic>> q = _col;

      if (categoryId != null) {
        q = q.where('categoryId', isEqualTo: categoryId.value);
      }

      if (status != null) {
        q = q.where('status', isEqualTo: status.name);
      }

      if (fromDate != null) {
        q = q.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate!));
      }

      if (toDate != null) {
        q = q.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(toDate!));
      }

      final snapshot = await q.get();
      var requests = snapshot.docs.map((doc) => DTOMapper.serviceRequestFromJson(doc.data())).toList();

      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        requests = requests.where((r) =>
            r.title.value.toLowerCase().contains(lowerQuery) ||
            r.description.toLowerCase().contains(lowerQuery)).toList();
      }

      return Result.ok(requests);
    } catch (e) {
      return Result.err(RepositoryFailure('Error en búsqueda: $e'));
    }
  }
}