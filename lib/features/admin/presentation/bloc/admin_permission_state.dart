part of 'admin_permission_cubit.dart';

abstract class AdminPermissionState extends Equatable {
  const AdminPermissionState();
  
  @override
  List<Object> get props => [];
}

class AdminPermissionInitial extends AdminPermissionState {}

class AdminPermissionLoading extends AdminPermissionState {}

class AdminPermissionSuccess extends AdminPermissionState {
  final bool isAdmin;
  
  const AdminPermissionSuccess(this.isAdmin);
  
  @override
  List<Object> get props => [isAdmin];
}

class AdminPermissionError extends AdminPermissionState {
  final String message;
  
  const AdminPermissionError(this.message);
  
  @override
  List<Object> get props => [message];
}

class AdminRegistrationSuccess extends AdminPermissionState {}

class AdminCodeValidationSuccess extends AdminPermissionState {
  final bool isValid;
  
  const AdminCodeValidationSuccess(this.isValid);
  
  @override
  List<Object> get props => [isValid];
}
