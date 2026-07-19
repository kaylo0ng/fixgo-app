import 'package:fixgo/domain/services/domain_services.dart';
import 'package:fixgo/domain/request/service_request.dart';
import 'package:fixgo/domain/request/offer.dart';
import 'package:fixgo/domain/technician/technician_profile.dart';
import 'package:fixgo/domain/core/value_objects.dart';
import 'package:fixgo/domain/core/enums/service_request_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OfferMatchingService', () {
    late OfferMatchingService service;
    
    setUp(() {
      service = const OfferMatchingService();
    });

    test('returns empty list when no technicians available', () {
      final request = _createRequest();
      final result = service.findBestOffers(
        request: request,
        availableTechnicians: [],
        existingOffers: [],
      );

      expect(result.isOk, true);
      expect(result.getOrThrow(), isEmpty);
    });

    test('filters technicians by category', () {
      final request = _createRequest(categoryId: 'plumbing');
      final techPlumbing = _createTechnician(id: 'tech1', categories: ['plumbing']);
      final techElectrical = _createTechnician(id: 'tech2', categories: ['electrical']);
      
      final result = service.findBestOffers(
        request: request,
        availableTechnicians: [techPlumbing, techElectrical],
        existingOffers: [],
      );

      expect(result.isOk, true);
      final offers = result.getOrThrow();
      expect(offers.length, 1);
      expect(offers.first.technicianId, 'tech1');
    });

    test('only considers verified technicians', () {
      final request = _createRequest();
      final techVerified = _createTechnician(id: 'tech1', verified: true);
      final techUnverified = _createTechnician(id: 'tech2', verified: false);
      
      final result = service.findBestOffers(
        request: request,
        availableTechnicians: [techVerified, techUnverified],
        existingOffers: [],
      );

      expect(result.isOk, true);
      final offers = result.getOrThrow();
      expect(offers.length, 1);
      expect(offers.first.technicianId, 'tech1');
    });

    test('prioritizes technicians with existing offers', () {
      final request = _createRequest();
      final techWithOffer = _createTechnician(id: 'tech1');
      final techWithoutOffer = _createTechnician(id: 'tech2');
      final existingOffer = Offer(
        id: 'offer1',
        requestId: request.id,
        technicianId: 'tech1',
        proposedPrice: Price(100),
        estimatedDuration: DurationMinutes(60),
        message: 'Existing offer',
        status: OfferStatus.pending,
        createdAt: DateTime.now(),
      );
      
      final result = service.findBestOffers(
        request: request,
        availableTechnicians: [techWithOffer, techWithoutOffer],
        existingOffers: [existingOffer],
      );

      expect(result.isOk, true);
      final offers = result.getOrThrow();
      expect(offers.length, 2);
      expect(offers.first.technicianId, 'tech1');
    });

    test('respects maxResults limit', () {
      final request = _createRequest();
      final technicians = List.generate(10, (i) => _createTechnician(id: 'tech$i'));
      
      final result = service.findBestOffers(
        request: request,
        availableTechnicians: technicians,
        existingOffers: [],
        maxResults: 3,
      );

      expect(result.isOk, true);
      expect(result.getOrThrow().length, 3);
    });
  });

  group('PricingCalculator', () {
    late PricingCalculator calculator;
    
    setUp(() {
      calculator = const PricingCalculator();
    });

    test('calculates base price when no modifiers', () {
      final basePrice = Price(100);
      final duration = DurationMinutes(60);
      
      final result = calculator.calculateFinalPrice(
        basePrice: basePrice,
        duration: duration,
      );
      
      expect(result.value, 100);
    });

    test('adjusts price with technician rate', () {
      final basePrice = Price(100);
      final duration = DurationMinutes(60);
      final technicianRate = 200.0;
      
      final result = calculator.calculateFinalPrice(
        basePrice: basePrice,
        duration: duration,
        technicianRate: technicianRate,
      );
      
      expect(result.value, 150);
    });

    test('adds distance surcharge', () {
      final basePrice = Price(100);
      final duration = DurationMinutes(60);
      final distanceKm = 20.0;
      
      final result = calculator.calculateFinalPrice(
        basePrice: basePrice,
        duration: duration,
        distanceKm: distanceKm,
      );
      
      expect(result.value, 150);
    });

    test('applies urgent surcharge', () {
      final basePrice = Price(100);
      final duration = DurationMinutes(60);
      
      final result = calculator.calculateFinalPrice(
        basePrice: basePrice,
        duration: duration,
        isUrgent: true,
      );
      
      expect(result.value, 125);
    });

    test('calculates platform fee', () {
      final totalPrice = Price(100);
      
      final result = calculator.calculatePlatformFee(totalPrice, percentage: 0.15);
      
      expect(result.value, 15);
    });
  });

  group('RatingCalculator', () {
    late RatingCalculator calculator;
    
    setUp(() {
      calculator = const RatingCalculator();
    });

    test('calculates average from ratings', () {
      final ratings = [RatingValue(5), RatingValue(4), RatingValue(3)];
      
      final result = calculator.calculateAverage(ratings: ratings);
      
      expect(result.value, 4.0);
    });

    test('incorporates current average', () {
      final ratings = [RatingValue(5)];
      final currentAverage = RatingValue(3);
      final currentCount = 2;
      
      final result = calculator.calculateAverage(
        ratings: ratings,
        currentAverage: currentAverage,
        currentCount: currentCount,
      );
      
      expect(result.value, 3.7);
    });

    test('returns 0 when no ratings', () {
      final result = calculator.calculateAverage(ratings: [], currentAverage: null, currentCount: null);
      
      expect(result.value, 0);
    });
  });
}

ServiceRequest _createRequest({
  String id = 'req1',
  String categoryId = 'plumbing',
}) {
  return ServiceRequest(
    id: id,
    clientId: 'client1',
    categoryId: ServiceCategoryId.create(categoryId).getOrThrow(),
    title: NonEmptyString.create('Test request').getOrThrow(),
    description: 'Description',
    address: 'Test address',
    coordinates: Coordinates.create(0, 0).getOrThrow(),
    status: ServiceRequestStatus.published,
    createdAt: DateTime.now(),
    estimatedPrice: Price(100),
  );
}

TechnicianProfile _createTechnician({
  required String id,
  List<String> categories = const ['plumbing'],
  bool verified = true,
}) {
  return TechnicianProfile(
    id: id,
    userId: 'user_$id',
    bio: NonEmptyString.create('Bio').getOrThrow(),
    categoryIds: categories.map((c) => ServiceCategoryId.create(c).getOrThrow()).toList(),
    serviceArea: Coordinates.create(0, 0).getOrThrow(),
    averageRating: RatingValue(4),
    completedServices: 10,
    isVerified: verified,
    hourlyRate: Price(100),
    availabilityRadiusKm: 20,
    createdAt: DateTime.now(),
  );
}