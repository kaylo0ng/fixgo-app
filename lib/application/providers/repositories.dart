import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fixgo/domain/request/repositories.dart';
import 'package:fixgo/domain/technician/repositories.dart';
import 'package:fixgo/domain/user/repositories.dart' as user_domain;
import 'package:fixgo/domain/category/repositories.dart' as category_domain;
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

final userRepositoryProvider = Provider<user_domain.IUserRepository>((ref) {
  return MockUserRepository();
});

final categoryRepositoryProvider = Provider<category_domain.ICategoryRepository>((ref) {
  return MockCategoryRepository();
});