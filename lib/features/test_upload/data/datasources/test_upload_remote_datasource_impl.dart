import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:korean_language_app/core/utils/exception_mapper.dart';
import 'package:korean_language_app/features/test_upload/data/datasources/test_upload_remote_datasource.dart';
import 'package:korean_language_app/features/tests/data/models/test_item.dart';

class FirestoreTestUploadDataSourceImpl implements TestUploadRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final String testsCollection = 'tests';

  FirestoreTestUploadDataSourceImpl({
    required this.firestore,
    required this.storage,
  });

  @override
  Future<TestItem> uploadTest(TestItem test, {File? imageFile}) async {
    try {
      if (test.title.isEmpty || test.description.isEmpty || test.questions.isEmpty) {
        throw ArgumentError('Test title, description, and questions cannot be empty');
      }
      
      // Generate new document reference to get ID
      final docRef = test.id.isEmpty 
          ? firestore.collection(testsCollection).doc() 
          : firestore.collection(testsCollection).doc(test.id);
      
      final testId = docRef.id;
      var finalTest = test.copyWith(id: testId);
      
      String? uploadedImagePath;
      
      try {
        // Upload image first if provided
        if (imageFile != null) {
          final (imageUrl, imagePath) = await _uploadTestImage(testId, imageFile);
          uploadedImagePath = imagePath;
          finalTest = finalTest.copyWith(
            imageUrl: imageUrl,
            imagePath: imagePath,
          );
        }
        
        // Now create the test document with all data
        final testData = finalTest.toJson();
        testData['titleLowerCase'] = finalTest.title.toLowerCase();
        testData['descriptionLowerCase'] = finalTest.description.toLowerCase();
        testData['createdAt'] = FieldValue.serverTimestamp();
        testData['updatedAt'] = FieldValue.serverTimestamp();
        
        await docRef.set(testData);
        
        return finalTest.copyWith(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
      } catch (e) {
        // Clean up uploaded image on failure
        if (uploadedImagePath != null) {
          await _deleteImageByPath(uploadedImagePath);
        }
        throw Exception('Failed to create test: $e');
      }
    } on FirebaseException catch (e) {
      throw ExceptionMapper.mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to upload test: $e');
    }
  }

  @override
  Future<TestItem> updateTest(String testId, TestItem updatedTest, {File? imageFile}) async {
    try {
      final docRef = firestore.collection(testsCollection).doc(testId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        throw Exception('Test not found');
      }
      
      final existingData = docSnapshot.data() as Map<String, dynamic>;
      var finalTest = updatedTest;
      
      String? newImagePath;
      String? oldImagePath = existingData['imagePath'] as String?;
      
      try {
        // Upload new image if provided
        if (imageFile != null) {
          final (imageUrl, imagePath) = await _uploadTestImage(testId, imageFile);
          newImagePath = imagePath;
          finalTest = finalTest.copyWith(
            imageUrl: imageUrl,
            imagePath: imagePath,
          );
        }
        
        // Update the document
        final updateData = finalTest.toJson();
        updateData['titleLowerCase'] = finalTest.title.toLowerCase();
        updateData['descriptionLowerCase'] = finalTest.description.toLowerCase();
        updateData['updatedAt'] = FieldValue.serverTimestamp();
        
        await docRef.update(updateData);
        
        // Only delete old image after successful update
        if (newImagePath != null && oldImagePath != null && oldImagePath != newImagePath) {
          await _deleteImageByPath(oldImagePath);
        }
        
        // Return the updated test with current timestamp
        return finalTest.copyWith(updatedAt: DateTime.now());
        
      } catch (e) {
        // Clean up newly uploaded image on failure
        if (newImagePath != null) {
          await _deleteImageByPath(newImagePath);
        }
        rethrow;
      }
    } on FirebaseException catch (e) {
      throw ExceptionMapper.mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to update test: $e');
    }
  }

  @override
  Future<bool> deleteTest(String testId) async {
    try {
      final docRef = firestore.collection(testsCollection).doc(testId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        throw Exception('Test not found');
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      
      // Delete associated files first
      await _deleteAssociatedFiles(data);
      
      // Then delete the document
      await docRef.delete();
      
      return true;
    } on FirebaseException catch (e) {
      throw ExceptionMapper.mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to delete test: $e');
    }
  }

  @override
  Future<DateTime?> getTestLastUpdated(String testId) async {
    try {
      final docSnapshot = await firestore.collection(testsCollection).doc(testId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      
      if (data.containsKey('updatedAt') && data['updatedAt'] != null) {
        return (data['updatedAt'] as Timestamp).toDate();
      }
      
      return null;
    } on FirebaseException catch (e) {
      throw ExceptionMapper.mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to get test last updated: $e');
    }
  }

  @override
  Future<String?> regenerateUrlFromPath(String storagePath) async {
    try {
      if (storagePath.isEmpty) {
        return null;
      }
      
      final fileRef = storage.ref().child(storagePath);
      final downloadUrl = await fileRef.getDownloadURL();
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw ExceptionMapper.mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to regenerate URL: $e');
    }
  }

  @override
  Future<bool> verifyUrlIsWorking(String url) async {
    try {
      if (url.startsWith('https://firebasestorage.googleapis.com')) {
        try {
          final storageRef = storage.refFromURL(url);
          await storageRef.getMetadata();
          return true;
        } catch (e) {
          if (kDebugMode) {
            print('Storage URL validation failed: $e');
          }
          return false;
        }
      } else {
        final httpClient = HttpClient();
        final request = await httpClient.headUrl(Uri.parse(url));
        final response = await request.close();
        return response.statusCode >= 200 && response.statusCode < 300;
      }
    } catch (e) {
      return false;
    }
  }

  /// Private helper method to upload test image atomically
  Future<(String, String)> _uploadTestImage(String testId, File imageFile) async {
    try {
      final storagePath = 'tests/$testId/test_image.jpg';
      final fileRef = storage.ref().child(storagePath);
      
      final uploadTask = await fileRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg')
      );
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      if (downloadUrl.isEmpty) {
        throw Exception('Failed to get download URL for uploaded image');
      }
      
      return (downloadUrl, storagePath);
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  /// Private helper method to delete image by storage path
  Future<void> _deleteImageByPath(String storagePath) async {
    try {
      if (storagePath.isNotEmpty) {
        final fileRef = storage.ref().child(storagePath);
        await fileRef.delete();
      }
    } catch (e) {
      // Log but don't throw - deletion of old image shouldn't block update
      if (kDebugMode) {
        print('Failed to delete image at $storagePath: $e');
      }
    }
  }

  /// Private helper method to delete all associated files
  Future<void> _deleteAssociatedFiles(Map<String, dynamic> data) async {
    // Delete image by path if exists
    if (data.containsKey('imagePath') && data['imagePath'] != null) {
      await _deleteImageByPath(data['imagePath'] as String);
    }
    
    // Fallback: delete by URL
    if (data.containsKey('imageUrl') && data['imageUrl'] != null) {
      try {
        final imageRef = storage.refFromURL(data['imageUrl'] as String);
        await imageRef.delete();
      } catch (e) {
        // Log but continue
        if (kDebugMode) {
          print('Failed to delete image by URL: $e');
        }
      }
    }
  }
}