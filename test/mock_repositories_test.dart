import 'package:fixgo/domain/core/result.dart';
import 'package:fixgo/domain/request/service_request.dart';
import 'package:fixgo/domain/request/offer.dart';
import 'package:fixgo/domain/technician/technician_profile.dart';
import 'package:fixgo/domain/rating/rating.dart';
import 'package:fixgo/domain/category/service_category.dart';
import 'package:fixgo/domain/user/app_user.dart';
import 'package:fixgo/domain/core/value_objects.dart';
import 'package:fixgo/infrastructure/repositories/mock_repositories.dart';
import 'package:fixgo/domain/core/enums/service_request_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockServiceRequestRepository', () {
    late MockServiceRequestRepository repository;
    
    setUp(() {
      repository = MockServiceRequestRepository();
    });

    test('create and get by id', () async {
      final request = _createRequest(id: 'req1');
      
      await repository.create(request);
      final result = await repository.getById(RequestId.create('req1').getOrThrow());
      
      expect(result.isOk, true);
      expect(result.getOrThrow().id, 'req1');
    });

    test('getById returns NotFound for non-existent', () async {
      final result = await repository.getById(RequestId.create('nonexistent').getOrThrow());
      
      expect(result.isErr, true);
      expect(result.failure, isA<NotFoundFailure>());
    });

    test('getByClientId filters correctly', () async {
      final req1 = _createRequest(id: 'req1', clientId: 'client1');
      final req2 = _createRequest(id: 'req2', clientId: 'client2');
      final req3 = _createRequest(id: 'req3', clientId: 'client1');
      
      await repository.create(req1);
      await repository.create(req2);
      await repository.create(req3);
      
      final result = await repository.getByClientId(UserId.create('client1').getOrThrow());
      
      expect(result.isOk, true);
      expect(result.getOrThrow().length, 2);
      expect(result.getOrThrow().every((r) => r.clientId == 'client1'), true);
    });

    test('getOpenRequests returns only open requests', () async {
      final openReq = _createRequest(id: 'open1');
      final assignedReq = _createRequest(id: 'assigned1')
          .copyWith(status: ServiceRequestStatus.technicianSelected);
      final completedReq = _createRequest(id: 'completed1')
          .copyWith(status: ServiceRequestStatus.completed);
      
      await repository.create(openReq);
      await repository.create(assignedReq);
      await repository.create(completedReq);
      
      final result = await repository.getOpenRequests();
      
      expect(result.isOk, true);
      // published and technicianSelected are considered open (can receive offers)
      expect(result.getOrThrow().length, 2);
      expect(result.getOrThrow().any((r) => r.id == 'open1'), true);
      expect(result.getOrThrow().any((r) => r.id == 'assigned1'), true);
    });

    test('update modifies existing request', () async {
      final request = _createRequest(id: 'req1');
      await repository.create(request);
      
      final updated = request.copyWith(description: 'Updated');
      final updateResult = await repository.update(updated);
      
      expect(updateResult.isOk, true);
      
      final getResult = await repository.getById(RequestId.create('req1').getOrThrow());
      expect(getResult.getOrThrow().description, 'Updated');
    });

    test('delete removes request', () async {
      final request = _createRequest(id: 'req1');
      await repository.create(request);
      
      await repository.delete(RequestId.create('req1').getOrThrow());
      
      final result = await repository.getById(RequestId.create('req1').getOrThrow());
      expect(result.isErr, true);
    });

    test('search filters by query', () async {
      final req1 = _createRequest(id: 'req1', title: 'Plumbing emergency');
      final req2 = _createRequest(id: 'req2', title: 'Electrical issue');
      
      await repository.create(req1);
      await repository.create(req2);
      
      final result = await repository.search(query: 'plumbing');
      
      expect(result.isOk, true);
      expect(result.getOrThrow().length, 1);
      expect(result.getOrThrow().first.id, 'req1');
    });

    test('search filters by category', () async {
      final plumbingReq = _createRequest(id: 'req1', categoryId: 'plumbing');
      final electricalReq = _createRequest(id: 'req2', categoryId: 'electrical');
      
      await repository.create(plumbingReq);
      await repository.create(electricalReq);
      
      final result = await repository.search(categoryId: ServiceCategoryId.create('plumbing').getOrThrow());
      
      expect(result.isOk, true);
      expect(result.getOrThrow().length, 1);
      expect(result.getOrThrow().first.categoryId.value, 'plumbing');
    });

    test('search filters by status', () async {
      final publishedReq = _createRequest(id: 'req1')
          .copyWith(status: ServiceRequestStatus.published);
      final assignedReq = _createRequest(id: 'req2')
          .copyWith(status: ServiceRequestStatus.technicianSelected);
      
      await repository.create(publishedReq);
      await repository.create(assignedReq);
      
      final result = await repository.search(status: ServiceRequestStatus.published);
      
      expect(result.isOk, true);
      expect(result.getOrThrow().length, 1);
    });
  });

  group('MockOfferRepository', () {
    late MockOfferRepository repository;
    
    setUp(() {
      repository = MockOfferRepository();
    });

    test('create and get by id', () async {
      final offer = Offer(
        id: 'offer1',
        requestId: 'req1',
        technicianId: 'tech1',
        proposedPrice: Price(100),
        estimatedDuration: DurationMinutes(60),
        message: 'Test offer',
        status: OfferStatus.pending,
        createdAt: DateTime.now(),
      );
      
      await repository.create(offer);
      final result = await repository.getById('offer1');
      
      expect(result.isOk, true);
      expect(result.getOrThrow().id, 'offer1');
    });

    test('getByRequestId filters correctly', () async {
      final offer1 = Offer(id: 'o1', requestId: 'req1', technicianId: 't1', 
        proposedPrice: Price(100), estimatedDuration: DurationMinutes(60), 
        message: 'msg', status: OfferStatus.pending, createdAt: DateTime.now());
      final offer2 = Offer(id: 'o2', requestId: 'req1', technicianId: 't2', 
        proposedPrice: Price(200), estimatedDuration: DurationMinutes(60), 
        message: 'msg', status: OfferStatus.pending, createdAt: DateTime.now());
      final offer3 = Offer(id: 'o3', requestId: 'req2', technicianId: 't1', 
        proposedPrice: Price(100), estimatedDuration: DurationMinutes(60), 
        message: 'msg', status: OfferStatus.pending, createdAt: DateTime.now());
      
      await repository.create(offer1);
      await repository.create(offer2);
      await repository.create(offer3);
      
      final result = await repository.getByRequestId('req1');
      
      expect(result.isOk, true);
      expect(result.getOrThrow().length, 2);
    });
  });

  group('MockTechnicianProfileRepository', () {
    late MockTechnicianProfileRepository repository;
    
    setUp(() {
      repository = MockTechnicianProfileRepository();
    });

    test('getByUserId returns profile', () async {
      final profile = TechnicianProfile(
        id: 'profile1',
        userId: 'user1',
        bio: NonEmptyString.create('Bio').getOrThrow(),
        categoryIds: [ServiceCategoryId.create('plumbing').getOrThrow()],
        serviceArea: Coordinates.create(0, 0).getOrThrow(),
        averageRating: null,
        completedServices: 0,
        isVerified: false,
        hourlyRate: Price(100),
        availabilityRadiusKm: 20,
        createdAt: DateTime.now(),
      );
      
      await repository.create(profile);
      final result = await repository.getByUserId(UserId.create('user1').getOrThrow());
      
      expect(result.isOk, true);
      expect(result.getOrThrow().id, 'profile1');
    });

    test('getNearby filters by distance', () async {
      final nearbyProfile = TechnicianProfile(
        id: 'near',
        userId: 'user1',
        bio: NonEmptyString.create('Bio').getOrThrow(),
        categoryIds: [ServiceCategoryId.create('plumbing').getOrThrow()],
        serviceArea: Coordinates.create(0, 0).getOrThrow(),
        averageRating: null,
        completedServices: 0,
        isVerified: true,
        hourlyRate: Price(100),
        availabilityRadiusKm: 20,
        createdAt: DateTime.now(),
      );
      final farProfile = TechnicianProfile(
        id: 'far',
        userId: 'user2',
        bio: NonEmptyString.create('Bio').getOrThrow(),
        categoryIds: [ServiceCategoryId.create('plumbing').getOrThrow()],
        serviceArea: Coordinates.create(10, 10).getOrThrow(),
        averageRating: null,
        completedServices: 0,
        isVerified: true,
        hourlyRate: Price(100),
        availabilityRadiusKm: 20,
        createdAt: DateTime.now(),
      );
      
      await repository.create(nearbyProfile);
      await repository.create(farProfile);
      
      final result = await repository.getNearby(
        location: Coordinates.create(0, 0).getOrThrow(),
        radiusKm: 10,
      );
      
      expect(result.isOk, true);
      expect(result.getOrThrow().length, 1);
      expect(result.getOrThrow().first.id, 'near');
    });

    test('getTopRated returns sorted by rating', () async {
      final repo = MockTechnicianProfileRepository();
      for (final (id, rating, completed) in [
        ('low', 2.0, 5),
        ('high', 4.5, 20),
        ('mid', 3.5, 10),
      ]) {
        final profile = TechnicianProfile(
          id: id,
          userId: 'user_$id',
          bio: NonEmptyString.create('Bio').getOrThrow(),
          categoryIds: [ServiceCategoryId.create('plumbing').getOrThrow()],
          serviceArea: Coordinates.create(0, 0).getOrThrow(),
          averageRating: RatingValue(rating),
          completedServices: completed,
          isVerified: true,
          hourlyRate: Price(100),
          availabilityRadiusKm: 20,
          createdAt: DateTime.now(),
        );
        await repo.create(profile);
      }
      
      final result = await repo.getTopRated(limit: 2);
      
      expect(result.isOk, true);
      expect(result.getOrThrow().length, 2);
      expect(result.getOrThrow().first.id, 'high');
      expect(result.getOrThrow().last.id, 'mid');
    });
  });

  group('MockCategoryRepository', () {
    late MockCategoryRepository repository;
    
    setUp(() {
      repository = MockCategoryRepository();
    });

    test('getAll returns all categories', () async {
      final result = await repository.getAll();
      
      expect(result.isOk, true);
      expect(result.getOrThrow().length, 10); // 10 categories in mock
    });

    test('getById returns category', () async {
      final result = await repository.getById(ServiceCategoryId.create('plumbing').getOrThrow());
      
      expect(result.isOk, true);
      expect(result.getOrThrow().id, 'plumbing');
    });
  });
}

ServiceRequest _createRequest({
  String id = 'req1',
  String clientId = 'client1',
  String categoryId = 'plumbing',
  String title = 'Test Request',
  String description = 'Description',
  String address = 'Address',
  ServiceRequestStatus status = ServiceRequestStatus.published,
}) {
  return ServiceRequest(
    id: id,
    clientId: clientId,
    categoryId: ServiceCategoryId.create(categoryId).getOrThrow(),
    title: NonEmptyString.create(title).getOrThrow(),
    description: description,
    address: address,
    coordinates: Coordinates.create(0, 0).getOrThrow(),
    status: status,
    createdAt: DateTime.now(),
    estimatedPrice: Price(100),
  );
}
