import 'package:dartz/dartz.dart';
import 'package:korean_language_app/core/errors/failures.dart';
import 'package:korean_language_app/features/user_management/data/datasources/user_management_datasource.dart';
import 'package:korean_language_app/features/user_management/domain/repositories/user_management_repository.dart';
import 'package:korean_language_app/features/user_management/data/models/user_management_model.dart';

class UserManagementRepositoryImpl implements UserManagementRepository {
  final UserManagementDataSource _dataSource;
  
  UserManagementRepositoryImpl(this._dataSource);
  
  @override
  Future<Either<Failure, List<UserManagementModel>>> getAllUsers() async {
    try {
      final users = await _dataSource.getAllUsers();
      return Right(users);
    } catch (e) {
      return Left(UserManagementFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> updateUserStatus(String userId, bool isActive) async {
    try {
      await _dataSource.updateUserStatus(userId, isActive);
      return const Right(null);
    } catch (e) {
      return Left(UserManagementFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> deleteUser(String userId) async {
    try {
      await _dataSource.deleteUser(userId);
      return const Right(null);
    } catch (e) {
      return Left(UserManagementFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> resetUserPassword(String email) async {
    try {
      await _dataSource.resetUserPassword(email);
      return const Right(null);
    } catch (e) {
      return Left(UserManagementFailure(e.toString()));
    }
  }
}