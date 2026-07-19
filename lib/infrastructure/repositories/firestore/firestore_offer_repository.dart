import 'package:fixgo/domain/core/result.dart';
import 'package:fixgo/domain/request/offer.dart';
import 'package:fixgo/domain/request/repositories.dart';
import 'package:fixgo/infrastructure/models/mappers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreOfferRepository implements IOfferRepository {
  final CollectionReference<Map<String, dynamic>> _col = FirebaseFirestore.instance.collection('offers');

  @override
  Future<Result<Offer>> getById(String id) async {
    try {
      final doc = await _col.doc(id).get();
      if (!doc.exists) return Result.err(NotFoundFailure('Offer', id));
      return Result.ok(DTOMapper.offerFromJson(doc.data()!));
    } catch (e) {
      return Result.err(RepositoryFailure('Error al obtener oferta: $e'));
    }
  }

  @override
  Future<Result<List<Offer>>> getByRequestId(String requestId) async {
    try {
      final snapshot = await _col.where('requestId', isEqualTo: requestId).get();
      final offers = snapshot.docs.map((doc) => DTOMapper.offerFromJson(doc.data())).toList();
      return Result.ok(offers);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al obtener ofertas: $e'));
    }
  }

  @override
  Future<Result<List<Offer>>> getByTechnicianId(String technicianId) async {
    try {
      final snapshot = await _col.where('technicianId', isEqualTo: technicianId).get();
      final offers = snapshot.docs.map((doc) => DTOMapper.offerFromJson(doc.data())).toList();
      return Result.ok(offers);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al obtener ofertas: $e'));
    }
  }

  @override
  Future<Result<Offer>> create(Offer offer) async {
    try {
      final data = DTOMapper.offerToJson(offer);
      await _col.doc(offer.id).set(data);
      return Result.ok(offer);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al crear oferta: $e'));
    }
  }

  @override
  Future<Result<Offer>> update(Offer offer) async {
    try {
      final data = DTOMapper.offerToJson(offer);
      await _col.doc(offer.id).update(data);
      return Result.ok(offer);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al actualizar oferta: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _col.doc(id).delete();
      return Result.ok(null);
    } catch (e) {
      return Result.err(RepositoryFailure('Error al eliminar oferta: $e'));
    }
  }
}