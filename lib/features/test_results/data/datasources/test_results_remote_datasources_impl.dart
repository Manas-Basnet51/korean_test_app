import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:korean_language_app/core/utils/exception_mapper.dart';
import 'package:korean_language_app/features/test_results/data/datasources/test_results_remote_datasources.dart';
import 'package:korean_language_app/core/models/test_result.dart';

class FirestoreTestResultsDataSourceImpl implements TestResultsRemoteDataSource {
  final FirebaseFirestore firestore;
  final String usersCollection = 'users';
  final String userResultsSubcollection = 'test_results';

  FirestoreTestResultsDataSourceImpl({
    required this.firestore,
  });

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
        data['userId'] = userId;
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
}