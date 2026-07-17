import 'package:fixgo/domain/core/result.dart';
import 'package:fixgo/domain/request/service_request.dart';
import 'package:fixgo/domain/request/offer.dart';
import 'package:fixgo/domain/technician/technician_profile.dart';
import 'package:fixgo/domain/core/value_objects.dart';

class OfferMatchingService {
  const OfferMatchingService();

  Result<List<Offer>> findBestOffers({
    required ServiceRequest request, required List<TechnicianProfile> availableTechnicians,
    required List<Offer> existingOffers, int maxResults = 5,
  }) {
    final technicianOffers = <TechnicianProfile, Offer>{};

    for (final offer in existingOffers) {
      if (offer.isPending) {
        TechnicianProfile? tech;
        for (final t in availableTechnicians) {
          if (t.id == offer.technicianId) {
            tech = t;
            break;
          }
        }
        if (tech != null) technicianOffers[tech] = offer;
      }
    }

    final rankedTechnicians = availableTechnicians
        .where((t) => t.hasCategory(request.categoryId))
        .where((t) => t.canAcceptRequests)
        .map((t) => _TechnicianScore(
              technician: t, offer: technicianOffers[t],
              score: _calculateScore(request, t, technicianOffers[t]),
            ))
        .where((s) => s.score > 0)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final bestOffers = rankedTechnicians
        .take(maxResults)
        .map((s) => s.offer ??
            Offer(
              id: 'draft_${s.technician.id}', requestId: request.id,
              technicianId: s.technician.id, proposedPrice: _estimatePrice(request, s.technician),
              estimatedDuration: _estimateDuration(request, s.technician),
              message: 'Interesado en tu solicitud', status: OfferStatus.pending,
              createdAt: DateTime.now(),
            ))
        .toList();

    return Result.ok(bestOffers);
  }

  double _calculateScore(ServiceRequest request, TechnicianProfile technician, Offer? existingOffer) {
    double score = 0;
    score += technician.averageRating?.value ?? 0;
    score += technician.completedServices * 0.1;
    score += (100 - technician.distanceTo(request.coordinates)) * 0.05;

    if (existingOffer != null) {
      score += 10;
      if (existingOffer.proposedPrice.value <= (request.estimatedPrice?.value ?? double.infinity)) {
        score += 5;
      }
    }
    return score;
  }

  Price _estimatePrice(ServiceRequest request, TechnicianProfile technician) {
    final basePrice = request.estimatedPrice?.value ?? 500;
    final rate = technician.hourlyRate?.value ?? basePrice;
    final estimated = (rate * 1.2).roundToDouble();
    return Price(estimated.clamp(basePrice * 0.8, basePrice * 1.5));
  }

  DurationMinutes _estimateDuration(ServiceRequest request, TechnicianProfile technician) {
    return DurationMinutes(120);
  }
}

class _TechnicianScore {
  const _TechnicianScore({required this.technician, this.offer, required this.score});
  final TechnicianProfile technician;
  final Offer? offer;
  final double score;
}

class PricingCalculator {
  const PricingCalculator();

  Price calculateFinalPrice({
    required Price basePrice, required DurationMinutes duration,
    double? technicianRate, double? distanceKm, bool isUrgent = false,
  }) {
    double price = basePrice.value;
    if (technicianRate != null && technicianRate > 0) {
      price = (price + technicianRate * (duration.value / 60)) / 2;
    }
    if (distanceKm != null && distanceKm > 10) {
      price += (distanceKm - 10) * 5;
    }
    if (isUrgent) price *= 1.25;
    return Price(price.roundToDouble());
  }

  Price calculatePlatformFee(Price totalPrice, {double percentage = 0.15}) {
    final fee = (totalPrice.value * percentage).roundToDouble();
    return Price(fee.clamp(10, 500));
  }
}

class RatingCalculator {
  const RatingCalculator();

  RatingValue calculateAverage({
    required List<RatingValue> ratings, RatingValue? currentAverage, int? currentCount,
  }) {
    if (ratings.isEmpty && currentAverage == null) return RatingValue(0);

    final allRatings = <double>[];
    if (currentAverage != null && currentCount != null && currentCount > 0) {
      allRatings.addAll(List.filled(currentCount, currentAverage.value));
    }
    allRatings.addAll(ratings.map((r) => r.value));

    final sum = allRatings.reduce((a, b) => a + b);
    final avg = sum / allRatings.length;
    return RatingValue(double.parse(avg.toStringAsFixed(1)));
  }
}