import 'package:korean_language_app/features/auth/domain/entities/user.dart';
import 'package:korean_language_app/features/auth/domain/repositories/auth_repository.dart';

abstract class AuthService {
  String getCurrentUserId();
  UserEntity? getCurrentUser();
  Stream<UserEntity?> get userStream;
  bool get isAuthenticated;
  bool get isAnonymous;
}

class AuthServiceImpl implements AuthService {
  final AuthRepository _authRepository;
  
  AuthServiceImpl(this._authRepository);
  
  @override
  String getCurrentUserId() {
    final user = _authRepository.getCurrentUserSync();
    return user?.uid ?? '';
  }
  
  @override
  UserEntity? getCurrentUser() {
    return _authRepository.getCurrentUserSync();
  }
  
  @override
  Stream<UserEntity?> get userStream => _authRepository.user;
  
  @override
  bool get isAuthenticated {
    final user = getCurrentUser();
    return user != null;
  }
  
  @override
  bool get isAnonymous {
    // You'll need to add this property to your UserEntity or check differently
    final user = getCurrentUser();
    return user != null && user.email == null;
  }
}