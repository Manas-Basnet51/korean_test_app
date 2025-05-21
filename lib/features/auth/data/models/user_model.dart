import 'package:firebase_auth/firebase_auth.dart';
import 'package:korean_language_app/features/auth/domain/entities/user.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    super.email,
    super.displayName,
  });
  
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }
}