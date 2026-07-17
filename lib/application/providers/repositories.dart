import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fixgo/domain/request/repositories.dart';
import 'package:fixgo/domain/technician/repositories.dart';
import 'package:fixgo/domain/user/repositories.dart';
import 'package:fixgo/domain/category/repositories.dart';
import 'package:fixgo/infrastructure/repositories/mock_repositories.dart';

final serviceRequestRepositoryProvider = Provider<IServiceRequestRepository>((ref) {
  return MockServiceRequestRepository();
});

final offerRepositoryProvider = Provider<IOfferRepository>((ref) {
  return MockOfferRepository();
});

final technicianProfileRepositoryProvider = Provider<ITechnicianProfileRepository>((ref) {
  return MockTechnicianProfileRepository();
});

final ratingRepositoryProvider = Provider<IRatingRepository>((ref) {
  return MockRatingRepository();
});

final userRepositoryProvider = Provider<IUserRepository>((ref) {
  return MockUserRepository();
});

final categoryRepositoryProvider = Provider<ICategoryRepository>((ref) {
  return MockCategoryRepository();
});