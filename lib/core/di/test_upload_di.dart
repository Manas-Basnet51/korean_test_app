import 'package:get_it/get_it.dart';
import 'package:korean_language_app/features/test_upload/data/datasources/test_upload_remote_datasource.dart';
import 'package:korean_language_app/features/test_upload/data/datasources/test_upload_remote_datasource_impl.dart';
import 'package:korean_language_app/features/test_upload/data/repositories/test_upload_repository_impl.dart';
import 'package:korean_language_app/features/test_upload/domain/test_upload_repository.dart';
import 'package:korean_language_app/features/test_upload/presentation/bloc/test_upload_cubit.dart';

void registerTestUploadDependencies(GetIt sl) {
  // Cubits
  sl.registerFactory(() => TestUploadCubit(
    repository: sl(), 
    authService: sl(),
    adminService: sl(),
  ));
  
  // Repository
  sl.registerLazySingleton<TestUploadRepository>(
    () => TestUploadRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      adminService: sl(),
    ),
  );
  
  // Data Source
  sl.registerLazySingleton<TestUploadRemoteDataSource>(
    () => FirestoreTestUploadDataSourceImpl(
      firestore: sl(), 
      storage: sl(),
    ),
  );
}