import 'package:dartz/dartz.dart';
import 'package:korean_language_app/core/errors/failures.dart';
import 'package:korean_language_app/features/user_management/data/models/user_management_model.dart';

abstract class UserManagementRepository {
  Future<Either<Failure, List<UserManagementModel>>> getAllUsers();
  Future<Either<Failure, void>> updateUserStatus(String userId, bool isActive);
  Future<Either<Failure, void>> deleteUser(String userId);
  Future<Either<Failure, void>> resetUserPassword(String email);
}
