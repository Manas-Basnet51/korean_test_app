// lib/core/di/feature_di/admin_di.dart
import 'package:get_it/get_it.dart';
import 'package:korean_language_app/features/admin/data/service/admin_permission.dart';
import 'package:korean_language_app/features/admin/presentation/bloc/admin_permission_cubit.dart';
import 'package:korean_language_app/features/user_management/data/datasources/user_management_datasource.dart';
import 'package:korean_language_app/features/user_management/data/datasources/user_management_datasource_impl.dart';
import 'package:korean_language_app/features/user_management/data/repositories/user_management_repository_impl.dart';
import 'package:korean_language_app/features/user_management/domain/repositories/user_management_repository.dart';
import 'package:korean_language_app/features/user_management/presentation/bloc/user_management_cubit.dart';

void registerAdminDependencies(GetIt sl) {
  // Services
  sl.registerLazySingleton<AdminPermissionService>(
    () => FirebaseAdminPermissionService(
      firestore: sl(),
    )
  );
  
  // Cubits
  sl.registerLazySingleton<AdminPermissionCubit>(() => AdminPermissionCubit(sl()));
  sl.registerLazySingleton<UserManagementCubit>(() => UserManagementCubit(sl()));
  
  // Repository
  sl.registerLazySingleton<UserManagementRepository>(
    () => UserManagementRepositoryImpl(sl())
  );
  
  // Data Sources
  sl.registerLazySingleton<UserManagementDataSource>(
    () => FirebaseUserManagementDataSource(firestore: sl(), auth: sl())
  );
}