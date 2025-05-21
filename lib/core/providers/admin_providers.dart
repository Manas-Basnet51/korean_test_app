import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/di/di.dart';
import 'package:korean_language_app/features/admin/presentation/bloc/admin_permission_cubit.dart';
import 'package:korean_language_app/features/user_management/presentation/bloc/user_management_cubit.dart';

class AdminProviders {
  static List<BlocProvider> getProviders() {
    return [
      BlocProvider<AdminPermissionCubit>(
        create: (context) => sl<AdminPermissionCubit>(),
      ),
      BlocProvider<UserManagementCubit>(
        create: (context) => sl<UserManagementCubit>(),
      ),
    ];
  }
  
  /// Initialize admin configuration (call during app startup)
  // static Future<void> initializeAdminSettings() async {
  //   if (_adminPermissionService is FirebaseAdminPermissionService) {
  //     // Ensure admin code exists in Firestore
  //     await (_adminPermissionService as FirebaseAdminPermissionService).validateAdminCode('');
  //   }
  // }
}