import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/features/user_management/domain/repositories/user_management_repository.dart';
import 'package:korean_language_app/features/user_management/data/models/user_management_model.dart';

part 'user_management_state.dart';

class UserManagementCubit extends Cubit<UserManagementState> {
  final UserManagementRepository _repository;
  
  UserManagementCubit(this._repository) : super(UserManagementInitial());
  

  Future<void> loadUsers() async {
    emit(UserManagementLoading());
    
    final result = await _repository.getAllUsers();
    result.fold(
      (failure) => emit(UserManagementError(failure.message)),
      (users) => emit(UsersLoaded(users)),
    );
  }
  
  Future<void> updateUserStatus(String userId, bool currentStatus) async {
    emit(UserManagementLoading());
    
    final result = await _repository.updateUserStatus(userId, !currentStatus);
    result.fold(
      (failure) => emit(UserManagementError(failure.message)),
      (_) {
        emit(UserActionSuccess(!currentStatus 
            ? 'User activated successfully' 
            : 'User deactivated successfully'));
        loadUsers(); // Reload users after update
      },
    );
  }
  
  Future<void> deleteUser(String userId) async {
    emit(UserManagementLoading());
    
    final result = await _repository.deleteUser(userId);
    result.fold(
      (failure) => emit(UserManagementError(failure.message)),
      (_) {
        emit(const UserActionSuccess('User deleted successfully'));
        loadUsers(); // Reload users after deletion
      },
    );
  }
  
  Future<void> resetUserPassword(String email) async {
    emit(UserManagementLoading());
    
    final result = await _repository.resetUserPassword(email);
    result.fold(
      (failure) => emit(UserManagementError(failure.message)),
      (_) {
        emit(const UserActionSuccess('Password reset email sent successfully'));
      },
    );
  }
}