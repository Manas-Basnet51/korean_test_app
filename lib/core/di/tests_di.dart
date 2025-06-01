import 'package:get_it/get_it.dart';
import 'package:korean_language_app/features/tests/data/datasources/firestore_tests_remote_datasource_impl.dart';
import 'package:korean_language_app/features/tests/data/datasources/tests_local_datasource.dart';
import 'package:korean_language_app/features/tests/data/datasources/tests_local_datasource_impl.dart';
import 'package:korean_language_app/features/tests/data/datasources/tests_remote_datasource.dart';
import 'package:korean_language_app/features/tests/data/repositories/tests_repository_impl.dart';
import 'package:korean_language_app/features/tests/domain/repositories/tests_repository.dart';
import 'package:korean_language_app/features/tests/presentation/bloc/test_session/test_session_cubit.dart';
import 'package:korean_language_app/features/tests/presentation/bloc/tests_cubit.dart';

void registerTestsDependencies(GetIt sl) {
  // Cubits
  sl.registerFactory(() => TestsCubit(repository: sl(), authCubit: sl(),adminService: sl()));
  sl.registerFactory(() => TestSessionCubit(repository: sl(), authCubit: sl()));
  
  // Repository
  sl.registerLazySingleton<TestsRepository>(
    () => TestsRepositoryImpl(remoteDataSource: sl(),networkInfo: sl(),localDataSource: sl(), adminService: sl()),
  );
  
  // Data Source
  sl.registerLazySingleton<TestsRemoteDataSource>(
    () => FirestoreTestsDataSourceImpl(firestore: sl(), storage: sl()),
  );
  sl.registerLazySingleton<TestsLocalDataSource>(
    () => TestsLocalDataSourceImpl(sharedPreferences: sl()),
  );
}