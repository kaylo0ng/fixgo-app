class Offer {
  const Offer({
    required this.id,
    required this.serviceRequestId,
    required this.technicianId,
    required this.price,
    required this.message,
    required this.estimatedDuration,
    required this.createdAt,
    this.acceptedAt,
  });

  final String id;
  final String serviceRequestId;
  final String technicianId;
  final double price;
  final String message;
  final Duration estimatedDuration;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  bool get isAccepted => acceptedAt != null;
}
