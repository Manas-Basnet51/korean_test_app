// lib/presentation/bloc/auth/auth_state.dart
part of 'auth_cubit.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthGoogleLoading extends AuthState {}

class AuthAnonymousLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserEntity user;
  
  const Authenticated(this.user);
  
  @override
  List<Object?> get props => [user];
}

class AuthAnonymousSignIn extends AuthState {}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  
  const AuthError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class AuthPasswordResetSent extends AuthState {}