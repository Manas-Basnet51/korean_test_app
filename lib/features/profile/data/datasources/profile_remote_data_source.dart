import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

abstract class ProfileDataSource {
  Future<(bool, String)> checkAvailability();
  Future<Map<String, dynamic>> getProfile(String userId);
  Future<void> updateProfile(String userId, Map<String, dynamic> data);
  Future<String> uploadProfileImage(String userId, String filePath);
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
    bool isStorageAvailable;
    String message;
    try {
      // A simple test to see if we can access Firebase Storage
      final testRef = storage.ref().child('test.txt');
      await testRef.getMetadata();
      isStorageAvailable = true;
      message = 'Firebase Storage is available.';
    } catch (e) {
      // If we get an error, assume storage is not available
      isStorageAvailable = false;
      message = 'Firebase Storage is not available. Please set up a pay-as-you-go plan to enable this feature.';
      log('Firebase Storage not available: ${e.toString()}');
    }

    return (isStorageAvailable, message);
  }

  @override
  Future<Map<String, dynamic>> getProfile(String userId) async {
    final userDoc = await firestore.collection('users').doc(userId).get();
    
    if (userDoc.exists) {
      log(userDoc.data().toString());
      return userDoc.data() ?? {};
    } else {
      // Create a default profile if it doesn't exist
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
      
      // Save default profile to Firestore
      await firestore.collection('users').doc(userId).set(defaultProfile);
      
      return defaultProfile;
    }
  }

  @override
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await firestore.collection('users').doc(userId).update(data);
  }

  @override
  Future<String> uploadProfileImage(String userId, String filePath) async {
    final fileRef = storage.ref().child('profile_images/$userId.jpg');
    final uploadTask = await fileRef.putFile(File(filePath));
    return await uploadTask.ref.getDownloadURL();
  }

}