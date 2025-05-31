import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

abstract class ProfileDataSource {
  Future<(bool, String)> checkAvailability();
  Future<Map<String, dynamic>> getProfile(String userId);
  Future<void> updateProfile(String userId, Map<String, dynamic> data);
  Future<(String, String)> uploadProfileImage(String userId, String filePath);
  Future<String?> regenerateUrlFromPath(String storagePath);
}

// Firestore implementation of ProfileDataSource
class FirestoreProfileDataSource implements ProfileDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  FirestoreProfileDataSource({
    required this.firestore,
    required this.storage,
  });

  @override
  Future<(bool, String)> checkAvailability() async {
    try {
      final testRef = storage.ref().child('test.txt');
      await testRef.getMetadata();
      return (true, 'Firebase Storage is available.');
    } catch (e) {
      log('Firebase Storage not available: ${e.toString()}');
      return (false, 'Firebase Storage is not available. Please set up a pay-as-you-go plan to enable this feature.');
    }
  }

  @override
  Future<Map<String, dynamic>> getProfile(String userId) async {
    final userDoc = await firestore.collection('users').doc(userId).get();
    
    if (userDoc.exists) {
      log('Profile found for user: $userId');
      return userDoc.data() ?? {};
    } else {
      final user = FirebaseAuth.instance.currentUser;
      final defaultProfile = {
        'id': userId,
        'name': user?.displayName ?? 'User',
        'email': user?.email ?? '',
        'profileImageUrl': user?.photoURL ?? '',
        'topikLevel': 'I',
        'completedTests': 0,
        'averageScore': 0.0,
      };
      
      await firestore.collection('users').doc(userId).set(defaultProfile);
      log('Created default profile for user: $userId');
      return defaultProfile;
    }
  }

  @override
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await firestore.collection('users').doc(userId).update(data);
    log('Profile updated for user: $userId');
  }

  @override
  Future<(String, String)> uploadProfileImage(String userId, String filePath) async {
    final storagePath = 'profile_images/$userId.jpg';
    final fileRef = storage.ref().child(storagePath);
    final uploadTask = await fileRef.putFile(File(filePath));
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    
    log('Profile image uploaded for user: $userId');
    return (downloadUrl, storagePath);
  }

  @override
  Future<String?> regenerateUrlFromPath(String storagePath) async {
    if (storagePath.isEmpty) return null;
    
    try {
      final fileRef = storage.ref().child(storagePath);
      final newUrl = await fileRef.getDownloadURL();
      
      log('Regenerated URL for path: $storagePath');
      return newUrl;
    } catch (e) {
      log('Error regenerating URL: ${e.toString()}');
      rethrow;
    }
  }
}