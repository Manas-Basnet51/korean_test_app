import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:korean_language_app/features/admin/presentation/bloc/admin_permission_cubit.dart';
import 'package:korean_language_app/features/auth/presentation/bloc/auth_cubit.dart';

/// A route guard that ensures only admin users can access protected routes
class AdminRouteGuard {
  final BuildContext context;
  
  AdminRouteGuard(this.context);
  
  /// Check if the current user is an admin
  Future<bool> checkAdminAccess() async {
    final adminCubit = context.read<AdminPermissionCubit>();
    final authCubit = context.read<AuthCubit>();
    
    // Get the current user ID
    final userId = authCubit.getCurrentUserId();
    if (userId.isEmpty) {
      return false;
    }
    
    // Check if user is admin
    return await adminCubit.checkAdminStatus(userId);
  }
  
  /// Redirect to login or home page if user is not admin
  static String? redirectIfNotAdmin(BuildContext context, GoRouterState state) {
    // Can't check admin status synchronously, so we'll check in the page itself
    // and redirect there if needed
    return null;
  }
}

/// Mixin for admin-only page states
mixin AdminAccessMixin<T extends StatefulWidget> on State<T> {
  bool _checkedAdminStatus = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminAccess();
    });
  }
  
  /// Check if the current user is an admin and redirect if not
  Future<void> _checkAdminAccess() async {
    if (_checkedAdminStatus) return;
    
    final adminGuard = AdminRouteGuard(context);
    final isAdmin = await adminGuard.checkAdminAccess();
    
    if (!isAdmin && mounted) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to access this page'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Redirect to home page
      context.go('/home');
    }
    
    _checkedAdminStatus = true;
  }
}