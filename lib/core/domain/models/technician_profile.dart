class TechnicianProfile {
  const TechnicianProfile({
    required this.userId,
    required this.bio,
    required this.categoryIds,
    required this.averageRating,
    required this.completedServices,
    required this.isVerified,
  });

  final String userId;
  final String bio;
  final List<String> categoryIds;
  final double averageRating;
  final int completedServices;
  final bool isVerified;

  bool get hasReputation => completedServices > 0;
}
