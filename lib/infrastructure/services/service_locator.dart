import 'package:get_it/get_it.dart';
import 'package:fixgo/domain/request/repositories.dart';
import 'package:fixgo/domain/technician/repositories.dart';
import 'package:fixgo/domain/user/repositories.dart' as user_domain;
import 'package:fixgo/domain/category/repositories.dart' as category_domain;
import 'package:fixgo/infrastructure/repositories/mock_repositories.dart';
import 'package:fixgo/infrastructure/repositories/firestore/firestore_service_request_repository.dart';
import 'package:fixgo/infrastructure/repositories/firestore/firestore_offer_repository.dart';
import 'package:fixgo/infrastructure/repositories/firestore/firestore_other_repositories.dart';

final serviceLocator = GetIt.instance;

void setupDependencies({bool useMock = false}) {
  if (useMock) {
    serviceLocator.registerLazySingleton<IServiceRequestRepository>(
      () => MockServiceRequestRepository(),
    );
    serviceLocator.registerLazySingleton<IOfferRepository>(
      () => MockOfferRepository(),
    );
    serviceLocator.registerLazySingleton<ITechnicianProfileRepository>(
      () => MockTechnicianProfileRepository(),
    );
    serviceLocator.registerLazySingleton<IRatingRepository>(
      () => MockRatingRepository(),
    );
    serviceLocator.registerLazySingleton<user_domain.IUserRepository>(
      () => MockUserRepository(),
    );
    serviceLocator.registerLazySingleton<category_domain.ICategoryRepository>(
      () => MockCategoryRepository(),
    );
  } else {
    serviceLocator.registerLazySingleton<IServiceRequestRepository>(
      () => FirestoreServiceRequestRepository(),
    );
    serviceLocator.registerLazySingleton<IOfferRepository>(
      () => FirestoreOfferRepository(),
    );
    serviceLocator.registerLazySingleton<ITechnicianProfileRepository>(
      () => FirestoreTechnicianProfileRepository(),
    );
    serviceLocator.registerLazySingleton<IRatingRepository>(
      () => FirestoreRatingRepository(),
    );
    serviceLocator.registerLazySingleton<user_domain.IUserRepository>(
      () => FirestoreUserRepository(),
    );
    serviceLocator.registerLazySingleton<category_domain.ICategoryRepository>(
      () => FirestoreCategoryRepository(),
    );
  }
}