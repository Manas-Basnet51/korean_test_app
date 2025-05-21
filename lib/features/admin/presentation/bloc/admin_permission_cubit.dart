import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/features/admin/data/service/admin_permission.dart';

part 'admin_permission_state.dart';

class AdminPermissionCubit extends Cubit<AdminPermissionState> {
  final AdminPermissionService _adminService;
  
  AdminPermissionCubit(this._adminService) : super(AdminPermissionInitial());
  
  Future<bool> checkAdminStatus(String userId) async {
    if (userId.isEmpty) {
      emit(const AdminPermissionSuccess(false));
      return false;
    }
    
    emit(AdminPermissionLoading());
    try {
      final isAdmin = await _adminService.isUserAdmin(userId);
      emit(AdminPermissionSuccess(isAdmin));
      return isAdmin;
    } catch (e) {
      emit(AdminPermissionError('Failed to check admin status: ${e.toString()}'));
      return false;
    }
  }
  
  Future<bool> validateAdminCode(String adminCode) async {
    if (adminCode.isEmpty) {
      emit(const AdminPermissionError('Admin code cannot be empty'));
      return false;
    }
    
    emit(AdminPermissionLoading());
    try {
      final isValid = await _adminService.validateAdminCode(adminCode);
      if(isValid == true) {
        emit(AdminCodeValidationSuccess(isValid!));
        return isValid;
      }
      return false;
    } catch (e) {
      emit(AdminPermissionError('Failed to validate admin code: ${e.toString()}'));
      return false;
    }
  }
  
  Future<void> registerUserAsAdmin(String userId, String adminCode) async {
    if (userId.isEmpty) {
      emit(const AdminPermissionError('User ID cannot be empty'));
      return;
    }
    
    emit(AdminPermissionLoading());
    try {
      // Validate admin code first
      final isValid = await _adminService.validateAdminCode(adminCode);
      if(isValid != true) {
        emit(const AdminPermissionError('Invalid admin code'));
        return;
      }
      
      // Add user to admin collection
      await _adminService.registerAdmin(userId, additionalData: {
        'addedViaAdminCode': true
      });
      
      emit(AdminRegistrationSuccess());
      
      // Update cache
      _adminService.clearCache();
    } catch (e) {
      emit(AdminPermissionError('Failed to register as admin: ${e.toString()}'));
    }
  }
  
  void clearAdminCache() {
    _adminService.clearCache();
  }

  void reset() {
    emit(AdminPermissionInitial());
  }
}