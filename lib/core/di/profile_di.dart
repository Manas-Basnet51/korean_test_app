// lib/core/di/feature_di/profile_di.dart
import 'package:get_it/get_it.dart';
import 'package:korean_language_app/features/profile/data/datasources/profile_local_data_source.dart';
import 'package:korean_language_app/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:korean_language_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:korean_language_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:korean_language_app/features/profile/presentation/bloc/profile_cubit.dart';

void registerProfileDependencies(GetIt sl) {
  // Cubits
  sl.registerFactory(() => ProfileCubit(profileRepository: sl(), authService: sl()));
  
  // Repository
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl(),networkInfo: sl(),localDataSource: sl()),
  );
  
  // Data Source
  sl.registerLazySingleton<ProfileDataSource>(
    () => FirestoreProfileDataSource(firestore: sl(), storage: sl()),
  );
  sl.registerLazySingleton<ProfileLocalDataSource>(
    () => ProfileLocalDataSourceImpl(sharedPreferences: sl()),
  );
}