import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:korean_language_app/features/user_management/data/datasources/user_management_datasource.dart';
import 'package:korean_language_app/features/user_management/data/models/user_management_model.dart';

class FirebaseUserManagementDataSource implements UserManagementDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _adminCollectionPath = 'admin_users';
  
  FirebaseUserManagementDataSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore, 
       _auth = auth;
  
  @override
  Future<List<UserManagementModel>> getAllUsers() async {
    try {
      // Get all users from the users collection
      final userDocs = await _firestore.collection('users').get();
      
      // Get all admin users to check which users are admins
      final adminDocs = await _firestore.collection(_adminCollectionPath).get();
      final adminIds = adminDocs.docs.map((doc) => doc.id).toSet();
      
      // Convert documents to models
      return await Future.wait(
        userDocs.docs.map((doc) async {
          final isAdmin = adminIds.contains(doc.id);
          return UserManagementModel.fromFirestore(doc, isAdmin: isAdmin);
        }),
      );
    } catch (e) {
      if (kDebugMode) print('Error getting all users: $e');
      throw Exception('Failed to get users: $e');
    }
  }
  
  @override
  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) print('Error updating user status: $e');
      throw Exception('Failed to update user status: $e');
    }
  }
  
  @override
  Future<void> deleteUser(String userId) async {
    try {
      // We need admin SDK to delete users from Firebase Auth
      // This will only delete from Firestore
      
      // Delete from users collection
      await _firestore.collection('users').doc(userId).delete();
      
      // If user is admin, also delete from admin collection
      await _firestore.collection(_adminCollectionPath).doc(userId).delete();
      
      if (kDebugMode) {
        print('User deleted from Firestore. Note: To delete from Firebase Auth requires admin SDK on a backend.');
      }
    } catch (e) {
      if (kDebugMode) print('Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }
  
  @override
  Future<void> resetUserPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      if (kDebugMode) print('Error resetting password: $e');
      throw Exception('Failed to reset password: $e');
    }
  }
}
