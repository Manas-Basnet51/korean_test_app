import 'package:korean_language_app/features/user_management/data/models/user_management_model.dart';

abstract class UserManagementDataSource {
  Future<List<UserManagementModel>> getAllUsers();
  Future<void> updateUserStatus(String userId, bool isActive);
  Future<void> deleteUser(String userId);
  Future<void> resetUserPassword(String email);
}