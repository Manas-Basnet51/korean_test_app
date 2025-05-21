part of 'user_management_cubit.dart';

abstract class UserManagementState extends Equatable {
  const UserManagementState();
  
  @override
  List<Object> get props => [];
}

class UserManagementInitial extends UserManagementState {}

class UserManagementLoading extends UserManagementState {}

class UsersLoaded extends UserManagementState {
  final List<UserManagementModel> users;
  
  const UsersLoaded(this.users);
  
  @override
  List<Object> get props => [users];
}

class UserActionSuccess extends UserManagementState {
  final String message;
  
  const UserActionSuccess(this.message);
  
  @override
  List<Object> get props => [message];
}

class UserManagementError extends UserManagementState {
  final String message;
  
  const UserManagementError(this.message);
  
  @override
  List<Object> get props => [message];
}
