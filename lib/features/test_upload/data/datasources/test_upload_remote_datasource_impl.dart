import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:korean_language_app/core/utils/exception_mapper.dart';
import 'package:korean_language_app/features/test_upload/data/datasources/test_upload_remote_datasource.dart';
import 'package:korean_language_app/core/models/test_item.dart';
import 'package:korean_language_app/core/models/test_question.dart';
import 'package:korean_language_app/core/enums/question_type.dart';

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
      
      final uploadedPaths = <String>[];
      
      try {
        // Upload cover image first if provided
        if (imageFile != null) {
          final (imageUrl, imagePath) = await _uploadCoverImage(testId, imageFile);
          uploadedPaths.add(imagePath);
          finalTest = finalTest.copyWith(
            imageUrl: imageUrl,
            imagePath: imagePath,
          );
        }
        
        // Upload all question and answer images
        final updatedQuestions = <TestQuestion>[];
        for (final question in finalTest.questions) {
          final updatedQuestion = await _uploadQuestionImages(testId, question, uploadedPaths);
          updatedQuestions.add(updatedQuestion);
        }
        
        finalTest = finalTest.copyWith(questions: updatedQuestions);
        
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
        // Clean up uploaded files on failure
        await _cleanupUploadedFiles(uploadedPaths);
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
      
      final newUploadedPaths = <String>[];
      final oldPaths = <String>[];
      
      try {
        // Collect old paths for cleanup
        if (existingData.containsKey('imagePath') && existingData['imagePath'] != null) {
          oldPaths.add(existingData['imagePath'] as String);
        }
        
        // Collect old question and answer image paths
        if (existingData.containsKey('questions') && existingData['questions'] is List) {
          final existingQuestions = existingData['questions'] as List;
          for (final questionData in existingQuestions) {
            if (questionData is Map<String, dynamic>) {
              if (questionData.containsKey('questionImagePath') && questionData['questionImagePath'] != null) {
                oldPaths.add(questionData['questionImagePath'] as String);
              }
              
              if (questionData.containsKey('options') && questionData['options'] is List) {
                final options = questionData['options'] as List;
                for (final option in options) {
                  if (option is Map<String, dynamic> && 
                      option.containsKey('imagePath') && 
                      option['imagePath'] != null) {
                    oldPaths.add(option['imagePath'] as String);
                  }
                }
              }
            }
          }
        }
        
        // Upload new cover image if provided
        if (imageFile != null) {
          final (imageUrl, imagePath) = await _uploadCoverImage(testId, imageFile);
          newUploadedPaths.add(imagePath);
          finalTest = finalTest.copyWith(
            imageUrl: imageUrl,
            imagePath: imagePath,
          );
        }
        
        // Upload all question and answer images
        final updatedQuestions = <TestQuestion>[];
        for (final question in finalTest.questions) {
          final updatedQuestion = await _uploadQuestionImages(testId, question, newUploadedPaths);
          updatedQuestions.add(updatedQuestion);
        }
        
        finalTest = finalTest.copyWith(questions: updatedQuestions);
        
        // Update the document
        final updateData = finalTest.toJson();
        updateData['titleLowerCase'] = finalTest.title.toLowerCase();
        updateData['descriptionLowerCase'] = finalTest.description.toLowerCase();
        updateData['updatedAt'] = FieldValue.serverTimestamp();
        
        await docRef.update(updateData);
        
        // Clean up old files after successful update
        await _cleanupUploadedFiles(oldPaths);
        
        return finalTest.copyWith(updatedAt: DateTime.now());
        
      } catch (e) {
        // Clean up newly uploaded files on failure
        await _cleanupUploadedFiles(newUploadedPaths);
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

  /// Upload cover image for the test
  Future<(String, String)> _uploadCoverImage(String testId, File imageFile) async {
    try {
      final storagePath = 'tests/$testId/cover_image.jpg';
      final fileRef = storage.ref().child(storagePath);
      
      final uploadTask = await fileRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg')
      );
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      if (downloadUrl.isEmpty) {
        throw Exception('Failed to get download URL for uploaded cover image');
      }
      
      return (downloadUrl, storagePath);
    } catch (e) {
      throw Exception('Cover image upload failed: $e');
    }
  }

  /// Upload question and answer images
  Future<TestQuestion> _uploadQuestionImages(String testId, TestQuestion question, List<String> uploadedPaths) async {
    var updatedQuestion = question;
    
    // Upload question image if it has a local file path
    if (question.questionImagePath != null && 
        question.questionImagePath!.startsWith('/') && 
        File(question.questionImagePath!).existsSync()) {
      
      final questionImageFile = File(question.questionImagePath!);
      final (questionImageUrl, questionImagePath) = await _uploadQuestionImage(testId, question.id, questionImageFile);
      uploadedPaths.add(questionImagePath);
      
      updatedQuestion = updatedQuestion.copyWith(
        questionImageUrl: questionImageUrl,
        questionImagePath: questionImagePath,
      );
    }
    
    // Upload answer images
    final updatedOptions = <AnswerOption>[];
    for (int i = 0; i < question.options.length; i++) {
      final option = question.options[i];
      
      if (option.isImage && 
          option.imagePath != null && 
          option.imagePath!.startsWith('/') && 
          File(option.imagePath!).existsSync()) {
        
        final answerImageFile = File(option.imagePath!);
        final (answerImageUrl, answerImagePath) = await _uploadAnswerImage(testId, question.id, i, answerImageFile);
        uploadedPaths.add(answerImagePath);
        
        updatedOptions.add(option.copyWith(
          imageUrl: answerImageUrl,
          imagePath: answerImagePath,
        ));
      } else {
        updatedOptions.add(option);
      }
    }
    
    return updatedQuestion.copyWith(options: updatedOptions);
  }

  /// Upload question image
  Future<(String, String)> _uploadQuestionImage(String testId, String questionId, File imageFile) async {
    try {
      final storagePath = 'tests/$testId/questions/$questionId/question_image.jpg';
      final fileRef = storage.ref().child(storagePath);
      
      final uploadTask = await fileRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg')
      );
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      if (downloadUrl.isEmpty) {
        throw Exception('Failed to get download URL for question image');
      }
      
      return (downloadUrl, storagePath);
    } catch (e) {
      throw Exception('Question image upload failed: $e');
    }
  }

  /// Upload answer image
  Future<(String, String)> _uploadAnswerImage(String testId, String questionId, int answerIndex, File imageFile) async {
    try {
      final storagePath = 'tests/$testId/questions/$questionId/answers/$answerIndex.jpg';
      final fileRef = storage.ref().child(storagePath);
      
      final uploadTask = await fileRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg')
      );
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      if (downloadUrl.isEmpty) {
        throw Exception('Failed to get download URL for answer image');
      }
      
      return (downloadUrl, storagePath);
    } catch (e) {
      throw Exception('Answer image upload failed: $e');
    }
  }

  /// Clean up uploaded files
  Future<void> _cleanupUploadedFiles(List<String> paths) async {
    for (final path in paths) {
      try {
        if (path.isNotEmpty) {
          final fileRef = storage.ref().child(path);
          await fileRef.delete();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to delete file at $path: $e');
        }
      }
    }
  }

  /// Delete all associated files for a test
  Future<void> _deleteAssociatedFiles(Map<String, dynamic> data) async {
    final pathsToDelete = <String>[];
    
    // Collect cover image path
    if (data.containsKey('imagePath') && data['imagePath'] != null) {
      pathsToDelete.add(data['imagePath'] as String);
    }
    
    // Collect question and answer image paths
    if (data.containsKey('questions') && data['questions'] is List) {
      final questions = data['questions'] as List;
      for (final questionData in questions) {
        if (questionData is Map<String, dynamic>) {
          // Question image path
          if (questionData.containsKey('questionImagePath') && questionData['questionImagePath'] != null) {
            pathsToDelete.add(questionData['questionImagePath'] as String);
          }
          
          // Answer image paths
          if (questionData.containsKey('options') && questionData['options'] is List) {
            final options = questionData['options'] as List;
            for (final option in options) {
              if (option is Map<String, dynamic> && 
                  option.containsKey('imagePath') && 
                  option['imagePath'] != null) {
                pathsToDelete.add(option['imagePath'] as String);
              }
            }
          }
        }
      }
    }
    
    await _cleanupUploadedFiles(pathsToDelete);
    
    // Fallback: delete by URL for cover image
    if (data.containsKey('imageUrl') && data['imageUrl'] != null) {
      try {
        final imageRef = storage.refFromURL(data['imageUrl'] as String);
        await imageRef.delete();
      } catch (e) {
        if (kDebugMode) {
          print('Failed to delete cover image by URL: $e');
        }
      }
    }
  }
}