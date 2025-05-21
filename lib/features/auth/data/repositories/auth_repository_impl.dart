

import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:korean_language_app/core/errors/failures.dart';
import 'package:korean_language_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:korean_language_app/features/auth/data/models/user_model.dart';
import 'package:korean_language_app/features/auth/domain/entities/user.dart';
import 'package:korean_language_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource dataSource;
  
  AuthRepositoryImpl(this.dataSource);
  
  @override
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword(
    String email, 
    String password
  ) async {
    try {
      final user = await dataSource.signInWithEmailAndPassword(email, password);
      return Right(UserModel.fromFirebaseUser(user));
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'An unknown error occurred'));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword(
    String email, 
    String password,
    [String? name]
  ) async {
    try {
      final user = await dataSource.signUpWithEmailAndPassword(email, password);
      
      // If name is provided, update user profile
      if (name != null && name.isNotEmpty) {
        await user.updateDisplayName(name);
        // Reload user to get updated profile
        await user.reload();
        // Get fresh user data
        final updatedUser = dataSource.getCurrentUser();
        if (updatedUser != null) {
          return Right(UserModel.fromFirebaseUser(updatedUser));
        }
      }
      
      return Right(UserModel.fromFirebaseUser(user));
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'An unknown error occurred'));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signInAnonymously() async {
    try {
      await dataSource.signInAnonymously();
      return const Right(null);
    } catch(e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final user = await dataSource.signInWithGoogle();
      return Right(UserModel.fromFirebaseUser(user));
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'An unknown error occurred'));
    } catch (e) {
      log(e.toString());
      return Left(AuthFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await dataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await dataSource.resetPassword(email);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = dataSource.getCurrentUser();
      if (user != null) {
        return Right(UserModel.fromFirebaseUser(user));
      }
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
  
  @override
  UserEntity? getCurrentUserSync() {
    try {
      final user = dataSource.getCurrentUser();
      if (user != null) {
        return UserModel.fromFirebaseUser(user);
      }
      return null;
    } catch (e) {
      log('Error getting current user sync: $e');
      return null;
    }
  }
  
  @override
  Stream<UserEntity?> get user {
    return dataSource.userChanges.map((user) {
      if (user == null) return null;
      return UserModel.fromFirebaseUser(user);
    });
  }

  @override
  Future<Either<Failure, void>> deleteCurrentUser() async {
    try {
      final user = dataSource.getCurrentUser();
      if (user != null) {
        await user.delete();
        return const Right(null);
      }
      return const Left(AuthFailure('No current user to delete'));
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'An unknown error occurred'));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}