import 'package:fixgo/core/domain/enums/service_request_status.dart';
import 'package:fixgo/core/domain/enums/user_role.dart';
import 'package:fixgo/core/domain/models/app_user.dart';
import 'package:fixgo/core/domain/models/rating.dart';
import 'package:fixgo/core/domain/models/service_request.dart';
import 'package:fixgo/core/domain/models/technician_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('service request exposes open and finished states', () {
    final request = ServiceRequest(
      id: 'request-1',
      clientId: 'client-1',
      categoryId: 'plumbing',
      title: 'Kitchen leak',
      description: 'There is a leak under the sink.',
      address: 'Main street 123',
      status: ServiceRequestStatus.receivingOffers,
      createdAt: DateTime(2026),
    );

    expect(request.isOpen, isTrue);
    expect(request.isFinished, isFalse);
  });

  test('app user can be copied with a new role', () {
    final user = AppUser(
      id: 'user-1',
      fullName: 'FixGo User',
      email: 'user@fixgo.test',
      role: UserRole.client,
      createdAt: DateTime(2026),
    );

    final technician = user.copyWith(role: UserRole.technician);

    expect(technician.role, UserRole.technician);
    expect(technician.email, user.email);
  });

  test('technician profile knows when it has reputation', () {
    const profile = TechnicianProfile(
      userId: 'tech-1',
      bio: 'Certified home technician.',
      categoryIds: ['electricity'],
      averageRating: 4.8,
      completedServices: 12,
      isVerified: true,
    );

    expect(profile.hasReputation, isTrue);
  });

  test('rating requires a score between one and five', () {
    expect(
      () => Rating(
        id: 'rating-1',
        serviceRequestId: 'request-1',
        fromUserId: 'client-1',
        toUserId: 'tech-1',
        score: 6,
        comment: 'Invalid score',
        createdAt: DateTime(2026),
      ),
      throwsAssertionError,
    );
  });
}
