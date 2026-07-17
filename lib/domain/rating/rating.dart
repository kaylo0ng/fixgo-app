import 'package:fixgo/domain/core/result.dart';
import 'package:fixgo/domain/core/entity.dart';
import 'package:fixgo/domain/core/value_objects.dart';

class Rating extends Entity<Rating> implements Validatable {
  const Rating({
    required this.id, required this.requestId, required this.clientId,
    required this.technicianId, required this.score, required this.comment,
    required this.categories, required this.createdAt,
  });

  @override final String id;
  final String requestId;
  final String clientId;
  final String technicianId;
  final RatingValue score;
  final String comment;
  final Map<String, RatingValue> categories;
  final DateTime createdAt;

  @override bool get isValid => validationErrors.isEmpty;

  @override List<ValueFailure> get validationErrors {
    final errors = <ValueFailure>[];
    if (comment.trim().isNotEmpty && comment.length > 500) {
      errors.add(StringTooLong(comment, 500));
    }
    return errors;
  }

  static Result<Rating> create({
    required String id, required String requestId, required String clientId,
    required String technicianId, required double score, required String comment,
    Map<String, double>? categories,
  }) {
    final scoreResult = RatingValue.create(score);
    final commentResult = comment.trim().isEmpty
        ? Result.ok<String>('')
        : NonEmptyString.create(comment, maxLength: 500).map((v) => v.value);

    final catResults = <String, Result<RatingValue>>{};
    if (categories != null) {
      for (final entry in categories.entries) {
        catResults[entry.key] = RatingValue.create(entry.value);
      }
    }

    if (scoreResult.isErr) return Result.err(scoreResult.failure);
    if (commentResult.isErr) return Result.err(commentResult.failure);

    final catValues = <String, RatingValue>{};
    for (final entry in catResults.entries) {
      if (entry.value.isOk) {
        catValues[entry.key] = entry.value.value;
      }
    }

    return Result.ok(Rating(
      id: id, requestId: requestId, clientId: clientId,
      technicianId: technicianId, score: scoreResult.value, comment: commentResult.value,
      categories: catValues, createdAt: DateTime.now(),
    ));
  }

  bool get hasComment => comment.isNotEmpty;
  bool get hasCategories => categories.isNotEmpty;
}