import 'package:get_it/get_it.dart';
import 'package:korean_language_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:korean_language_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:korean_language_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:korean_language_app/features/auth/presentation/bloc/auth_cubit.dart';

void registerAuthDependencies(GetIt sl) {
  // Bloc/Cubit
  sl.registerFactory(() => AuthCubit(sl()));
  
  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );
  
  // Data sources
  sl.registerLazySingleton<AuthDataSource>(
    () => FirebaseAuthDataSource(sl(), sl()),
  );
}