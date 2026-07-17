class Rating {
  const Rating({
    required this.id,
    required this.serviceRequestId,
    required this.fromUserId,
    required this.toUserId,
    required this.score,
    required this.comment,
    required this.createdAt,
  }) : assert(score >= 1 && score <= 5);

  final String id;
  final String serviceRequestId;
  final String fromUserId;
  final String toUserId;
  final int score;
  final String comment;
  final DateTime createdAt;
}
