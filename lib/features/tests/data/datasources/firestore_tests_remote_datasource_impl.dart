import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:korean_language_app/core/enums/test_category.dart';
import 'package:korean_language_app/core/utils/exception_mapper.dart';
import 'package:korean_language_app/features/tests/data/datasources/tests_remote_datasource.dart';
import 'package:korean_language_app/core/models/test_item.dart';

class FirestoreTestsDataSourceImpl implements TestsRemoteDataSource {
  final FirebaseFirestore firestore;
  final String testsCollection = 'tests';
  
  DocumentSnapshot? _lastDocument;
  final Map<TestCategory, DocumentSnapshot?> _categoryLastDocuments = {};
  int? _totalTestsCount;
  final Map<TestCategory, int?> _categoryTestsCounts = {};
  DateTime? _lastCountFetch;
  final Map<TestCategory, DateTime?> _categoryLastCountFetches = {};

  FirestoreTestsDataSourceImpl({
    required this.firestore,
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
        _categoryLastDocuments[category] = null;
      }

      Query query = firestore.collection(testsCollection)
          .where('isPublished', isEqualTo: true)
          .where('category', isEqualTo: category.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .limit(pageSize);
      
      if (page > 0 && _categoryLastDocuments[category] != null) {
        query = query.startAfterDocument(_categoryLastDocuments[category]!);
      }
      
      final querySnapshot = await query.get();
      final docs = querySnapshot.docs;
      
      if (docs.isNotEmpty) {
        _categoryLastDocuments[category] = docs.last;
      }

      if (page == 0) {
        _updateCategoryTestsCount(category, docs.length, isExact: false);
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
  Future<bool> hasMoreTestsByCategory(TestCategory category, int currentCount) async {
    try {
      final lastFetch = _categoryLastCountFetches[category];
      final cachedCount = _categoryTestsCounts[category];
      
      if (cachedCount != null && 
          lastFetch != null &&
          DateTime.now().difference(lastFetch).inMinutes < 5) {
        return currentCount < cachedCount;
      }
      
      final countQuery = await firestore.collection(testsCollection)
          .where('isPublished', isEqualTo: true)
          .where('category', isEqualTo: category.toString().split('.').last)
          .count()
          .get();
      
      _updateCategoryTestsCount(category, countQuery.count!, isExact: true);
      
      return currentCount < _categoryTestsCounts[category]!;
    } on FirebaseException catch (e) {
      throw ExceptionMapper.mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to check for more tests by category: $e');
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

  void _updateTotalTestsCount(int count, {required bool isExact}) {
    if (isExact || _totalTestsCount == null || count > _totalTestsCount!) {
      _totalTestsCount = count;
      _lastCountFetch = DateTime.now();
    }
  }

  void _updateCategoryTestsCount(TestCategory category, int count, {required bool isExact}) {
    if (isExact || _categoryTestsCounts[category] == null || count > _categoryTestsCounts[category]!) {
      _categoryTestsCounts[category] = count;
      _categoryLastCountFetches[category] = DateTime.now();
    }
  }
}