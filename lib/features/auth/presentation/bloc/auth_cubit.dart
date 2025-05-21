import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/features/auth/domain/entities/user.dart';
import 'package:korean_language_app/features/auth/domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  
  AuthCubit(this._authRepository) : super(AuthInitial()) {
    checkCurrentUser();
  }
  
  Future<void> checkCurrentUser() async {
    emit(AuthLoading());
    final result = await _authRepository.getCurrentUser();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => user != null ? emit(Authenticated(user)) : emit(Unauthenticated()),
    );
  }
  
  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());
    final result = await _authRepository.signInWithEmailAndPassword(email, password);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> signInAnonymously() async {
    emit(AuthAnonymousLoading());
    try {
      await _authRepository.signInAnonymously();
      emit(AuthAnonymousSignIn());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthGoogleLoading());
    final result = await _authRepository.signInWithGoogle();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }
  
  Future<void> signUp(String email, String password, [String? name]) async {
    emit(AuthLoading());
    final result = await _authRepository.signUpWithEmailAndPassword(email, password, name);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }
  
  Future<void> signOut() async {
    emit(AuthLoading());
    final result = await _authRepository.signOut();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(Unauthenticated()),
    );
  }

  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      await _authRepository.resetPassword(email);
      emit(AuthPasswordResetSent());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  
  String getCurrentUserId() {
    final user = _authRepository.getCurrentUserSync();
    return user?.uid ?? '';
  }

  Future<void> deleteCurrentUser() async {
    emit(AuthLoading());
    final result = await _authRepository.deleteCurrentUser();
    result.fold(
      (failure) {
        emit(AuthError(failure.message));
        // Try signing out if deletion fails
        signOut();
      },
      (_) => emit(Unauthenticated()),
    );
  }
}