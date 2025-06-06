import 'package:get_it/get_it.dart';
import 'package:korean_language_app/features/test_results/data/datasources/test_results_local_datasources.dart';
import 'package:korean_language_app/features/test_results/data/datasources/test_results_local_datasources_impl.dart';
import 'package:korean_language_app/features/test_results/data/datasources/test_results_remote_datasources.dart';
import 'package:korean_language_app/features/test_results/data/datasources/test_results_remote_datasources_impl.dart';
import 'package:korean_language_app/features/test_results/data/repositories/test_result_repository_impl.dart';
import 'package:korean_language_app/features/test_results/domain/repositories/test_results_repository.dart';
import 'package:korean_language_app/features/test_results/presentation/bloc/test_results_cubit.dart';

void registerTestResultsDependencies(GetIt sl) {
  // Cubits
  sl.registerFactory(() => TestResultsCubit(
    repository: sl(),
    authService: sl(),
  ));
  
  // Repository
  sl.registerLazySingleton<TestResultsRepository>(
    () => TestResultsRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  
  // Data Sources
  sl.registerLazySingleton<TestResultsRemoteDataSource>(
    () => FirestoreTestResultsDataSourceImpl(
      firestore: sl(),
    ),
  );
  
  sl.registerLazySingleton<TestResultsLocalDataSource>(
    () => TestResultsLocalDataSourceImpl(
      storageService: sl(),
    ),
  );
}