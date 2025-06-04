import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:korean_language_app/core/enums/test_category.dart';
import 'package:korean_language_app/core/utils/exception_mapper.dart';
import 'package:korean_language_app/features/tests/data/datasources/tests_remote_datasource.dart';
import 'package:korean_language_app/features/tests/data/models/test_item.dart';
import 'package:korean_language_app/features/tests/data/models/test_result.dart';

class FirestoreTestsDataSourceImpl implements TestsRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final String testsCollection = 'tests';
  final String usersCollection = 'users';
  final String userResultsSubcollection = 'test_results';
  
  DocumentSnapshot? _lastDocument;
  int? _totalTestsCount;
  DateTime? _lastCountFetch;

  FirestoreTestsDataSourceImpl({
    required this.firestore,
    required this.storage,
  });

  @override
  Future<List<TestItem>> getTests({int page = 0, int pageSize = 5}) async {
    try {
      if (page == 0) {
        _lastDocument = null;
      }

      Query query = firestore.collection(testsCollection)
          .where('isPublished', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(pageSize);
      
      if (page > 0 && _lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }
      
      final querySnapshot = await query.get();
      final docs = querySnapshot.docs;
      
      if (docs.isNotEmpty) {
        _lastDocument = docs.last;
      }
      
      if (page == 0) {
        _updateTotalTestsCount(docs.length, isExact: false);
      }
      
      return docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; 
        return TestItem.fromJson(data);
      }).toList();
    } on FirebaseException catch (e) {
      throw ExceptionMapper.mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to fetch tests: $e');
    }
  }

  @override
  Future<List<TestItem>> getTestsByCategory(TestCategory category, {int page = 0, int pageSize = 5}) async {
    try {
      if (page == 0) {
        _lastDocument = null;
      }

      Query query = firestore.collection(testsCollection)
          .where('isPublished', isEqualTo: true)
          .where('category', isEqualTo: category.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .limit(pageSize);
      
      if (page > 0 && _lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }
      
      final querySnapshot = await query.get();
      final docs = querySnapshot.docs;
      
      if (docs.isNotEmpty) {
        _lastDocument = docs.last;
      }
      
      return docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; 
        return TestItem.fromJson(data);
      }).toList();
    } on FirebaseException catch (e) {
      throw ExceptionMapper.mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to fetch tests by category: $e');
    }
  }

  @override
  Future<bool> hasMoreTests(int currentCount) async {
    try {
      if (_totalTestsCount != null && 
          _lastCountFetch != null &&
          DateTime.now().difference(_lastCountFetch!).inMinutes < 5) {
        return currentCount < _totalTestsCount!;
      }
      
      final countQuery = await firestore.collection(testsCollection)
          .where('isPublished', isEqualTo: true)
          .count()
          .get();
      
      _updateTotalTestsCount(countQuery.count!, isExact: true);
      
      return currentCount < _totalTestsCount!;
    } on FirebaseException catch (e) {
      throw ExceptionMapper.mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to check for more tests: $e');
    }
  }

  @override
  Future<List<TestItem>> searchTests(String query) async {
    try {
      final normalizedQuery = query.toLowerCase();
      
      final titleQuery = firestore.collection(testsCollection)
          .where('isPublished', isEqualTo: true)
          .where('titleLowerCase', isGreaterThanOrEqualTo: normalizedQuery)
          .where('titleLowerCase', isLessThanOrEqualTo: '$normalizedQuery\uf8ff')
          .limit(10);
      
      final titleSnapshot = await titleQuery.get();
      final List<TestItem> results = titleSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TestItem.fromJson(data);
      }).toList();
      
      if (results.length < 5) {
        final descQuery = firestore.collection(testsCollection)
            .where('isPublished', isEqualTo: true)
            .where('descriptionLowerCase', isGreaterThanOrEqualTo: normalizedQuery)
            .where('descriptionLowerCase', isLessThanOrEqualTo: '$normalizedQuery\uf8ff')
            .limit(10);
            
        final descSnapshot = await descQuery.get();
        final descResults = descSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return TestItem.fromJson(data);
        }).toList();
        
        for (final test in descResults) {
          if (!results.any((t) => t.id == test.id)) {
            results.add(test);
          }
        }
      }
      
      return results;
    } on FirebaseException catch (e) {
      throw ExceptionMapper.mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to search tests: $e');
    }
  }

  @override
  Future<TestItem?> getTestById(String testId) async {
    try {
      final docSnapshot = await firestore.collection(testsCollection).doc(testId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      data['id'] = docSnapshot.id;
      
      return TestItem.fromJson(data);
    } on FirebaseException catch (e) {
      throw ExceptionMapper.mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to get test by ID: $e');
    }
  }

  @override
  Future<bool> uploadTest(TestItem test) async {
    try {
      if (test.title.isEmpty || test.description.isEmpty || test.questions.isEmpty) {
        throw ArgumentError('Test title, description, and questions cannot be empty');
      }
      
      final docRef = test.id.isEmpty 
          ? firestore.collection(testsCollection).doc() 
          : firestore.collection(testsCollection).doc(test.id);
      
      final testData = test.toJson();
      if (test.id.isEmpty) {
        testData['id'] = docRef.id;
      }
      
      testData['titleLowerCase'] = test.title.toLowerCase();
      testData['descriptionLowerCase'] = test.description.toLowerCase();
      testData['createdAt'] = FieldValue.serverTimestamp();
      testData['updatedAt'] = FieldValue.serverTimestamp();
      
      await docRef.set(testData);
      
      if (_totalTestsCount != null) {
        _totalTestsCount = (_totalTestsCount ?? 0) + 1;
      }
      
      return true;
    } on FirebaseException catch (e) {
      throw ExceptionMapper.mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to upload test: $e');
    }
  }

  @override
  Future<bool> updateTest(String testId, TestItem updatedTest) async {
    try {
      final docRef = firestore.collection(testsCollection).doc(testId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        throw Exception('Test not found');
      }
      
      final updateData = updatedTest.toJson();
      
      updateData['titleLowerCase'] = updatedTest.title.toLowerCase();
      updateData['descriptionLowerCase'] = updatedTest.description.toLowerCase();
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      
      await docRef.update(updateData);
      
      return true;
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
      
      await _deleteAssociatedFiles(data);
      await docRef.delete();
      
      if (_totalTestsCount != null && _totalTestsCount! > 0) {
        _totalTestsCount = _totalTestsCount! - 1;
      }
      
      return true;
    } on FirebaseException catch (e) {
      throw ExceptionMapper.mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to delete test: $e');
    }
  }

  @override
  Future<(String, String)?> uploadTestImage(String testId, File imageFile) async {
    try {
      final storagePath = 'tests/$testId/test_image.jpg';
      final fileRef = storage.ref().child(storagePath);
      
      final uploadTask = await fileRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg')
      );
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return (downloadUrl, storagePath);
    } on FirebaseException catch (e) {
      throw ExceptionMapper.mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to upload test image: $e');
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

  // Test Results methods
  @override
  Future<bool> saveTestResult(TestResult result) async {
    try {

      final userResultsRef = firestore
          .collection(usersCollection)
          .doc(result.userId)
          .collection(userResultsSubcollection);

      final docRef = result.id.isEmpty 
          ? userResultsRef.doc() 
          : userResultsRef.doc(result.id);
      
      final resultData = result.toJson();

      resultData.remove('userId');
      
      if (result.id.isEmpty) {
        resultData['id'] = docRef.id;
      }
      
      resultData['createdAt'] = FieldValue.serverTimestamp();
      
      await docRef.set(resultData);
      
      return true;
    } on FirebaseException catch (e) {
      throw ExceptionMapper.mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to save test result: $e');
    }
  }

  @override
  Future<List<TestResult>> getUserTestResults(String userId, {int limit = 20}) async {
    try {
      final querySnapshot = await firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(userResultsSubcollection)
          .orderBy('completedAt', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['userId'] = userId; // Add back userId for your TestResult model
        return TestResult.fromJson(data);
      }).toList();
    } on FirebaseException catch (e) {
      throw ExceptionMapper.mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to get user test results: $e');
    }
  }

  @override
  Future<List<TestResult>> getTestResults(String testId, {int limit = 50}) async {
    try {
      final querySnapshot = await firestore
          .collectionGroup(userResultsSubcollection)
          .where('testId', isEqualTo: testId)
          .orderBy('completedAt', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // Extract userId from document path: users/{userId}/test_results/{resultId}
        data['userId'] = doc.reference.parent.parent!.id;
        return TestResult.fromJson(data);
      }).toList();
    } on FirebaseException catch (e) {
      throw ExceptionMapper.mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to get test results: $e');
    }
  }

  @override
  Future<TestResult?> getUserLatestResult(String userId, String testId) async {
    try {
      final querySnapshot = await firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(userResultsSubcollection)
          .where('testId', isEqualTo: testId)
          .orderBy('completedAt', descending: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      final data = querySnapshot.docs.first.data();
      data['id'] = querySnapshot.docs.first.id;
      data['userId'] = userId;
      
      return TestResult.fromJson(data);
    } on FirebaseException catch (e) {
      throw ExceptionMapper.mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to get user latest result: $e');
    }
  }

  Future<void> _deleteAssociatedFiles(Map<String, dynamic> data) async {
    if (data.containsKey('imageUrl') && data['imageUrl'] != null) {
      try {
        final imageRef = storage.refFromURL(data['imageUrl'] as String);
        await imageRef.delete();
      } catch (e) {
        // Log but continue
      }
    }
  }

  void _updateTotalTestsCount(int count, {required bool isExact}) {
    if (isExact || _totalTestsCount == null || count > _totalTestsCount!) {
      _totalTestsCount = count;
      _lastCountFetch = DateTime.now();
    }
  }
}