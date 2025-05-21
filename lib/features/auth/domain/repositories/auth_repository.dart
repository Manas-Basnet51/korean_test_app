import 'package:dartz/dartz.dart';
import 'package:korean_language_app/core/errors/failures.dart';
import 'package:korean_language_app/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword(String email, String password);
  Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword(String email, String password, [String? name]);
  Future<Either<Failure, void>> signInAnonymously();
  Future<Either<Failure, UserEntity>> signInWithGoogle();
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, void>> resetPassword(String email);
  Future<Either<Failure, UserEntity?>> getCurrentUser();
  UserEntity? getCurrentUserSync();
  Stream<UserEntity?> get user;
  Future<Either<Failure, void>> deleteCurrentUser();
}