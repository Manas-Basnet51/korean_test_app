import 'dart:convert';
import 'dart:developer' as dev;
import 'package:korean_language_app/core/services/storage_service.dart';
import 'package:korean_language_app/features/tests/data/datasources/tests_local_datasource.dart';
import 'package:korean_language_app/features/tests/data/models/test_item.dart';
import 'package:korean_language_app/features/tests/data/models/test_result.dart';

class TestsLocalDataSourceImpl implements TestsLocalDataSource {
  final StorageService _storageService;
  static const String testsKey = 'CACHED_TESTS';
  static const String lastSyncKey = 'LAST_TESTS_SYNC_TIME';
  static const String testHashesKey = 'TEST_HASHES';
  static const String userResultsPrefix = 'USER_RESULTS_';
  static const String latestResultPrefix = 'LATEST_RESULT_';

  TestsLocalDataSourceImpl({required StorageService storageService})
      : _storageService = storageService;

  @override
  Future<List<TestItem>> getAllTests() async {
    try {
      final jsonString = _storageService.getString(testsKey);
      if (jsonString == null) return [];
      
      final List<dynamic> decodedJson = json.decode(jsonString);
      return decodedJson.map((item) => TestItem.fromJson(item)).toList();
    } catch (e) {
      dev.log('Error reading tests from storage: $e');
      return [];
    }
  }

  @override
  Future<void> saveTests(List<TestItem> tests) async {
    try {
      final jsonList = tests.map((test) => test.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _storageService.setString(testsKey, jsonString);
    } catch (e) {
      dev.log('Error saving tests to storage: $e');
      throw Exception('Failed to save tests: $e');
    }
  }

  @override
  Future<void> addTest(TestItem test) async {
    try {
      final tests = await getAllTests();
      final existingIndex = tests.indexWhere((t) => t.id == test.id);
      
      if (existingIndex != -1) {
        tests[existingIndex] = test;
      } else {
        tests.add(test);
      }
      
      await saveTests(tests);
    } catch (e) {
      dev.log('Error adding test to storage: $e');
      throw Exception('Failed to add test: $e');
    }
  }

  @override
  Future<void> updateTest(TestItem test) async {
    try {
      final tests = await getAllTests();
      final testIndex = tests.indexWhere((t) => t.id == test.id);
      
      if (testIndex != -1) {
        tests[testIndex] = test;
        await saveTests(tests);
      } else {
        throw Exception('Test not found for update: ${test.id}');
      }
    } catch (e) {
      dev.log('Error updating test in storage: $e');
      throw Exception('Failed to update test: $e');
    }
  }

  @override
  Future<void> removeTest(String testId) async {
    try {
      final tests = await getAllTests();
      final updatedTests = tests.where((test) => test.id != testId).toList();
      await saveTests(updatedTests);
    } catch (e) {
      dev.log('Error removing test from storage: $e');
      throw Exception('Failed to remove test: $e');
    }
  }

  @override
  Future<void> clearAllTests() async {
    try {
      await _storageService.remove(testsKey);
      await _storageService.remove(lastSyncKey);
      await _storageService.remove(testHashesKey);
    } catch (e) {
      dev.log('Error clearing all tests from storage: $e');
    }
  }

  @override
  Future<bool> hasAnyTests() async {
    try {
      final tests = await getAllTests();
      return tests.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> getTestsCount() async {
    try {
      final tests = await getAllTests();
      return tests.length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<void> setLastSyncTime(DateTime dateTime) async {
    await _storageService.setInt(lastSyncKey, dateTime.millisecondsSinceEpoch);
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    final timestamp = _storageService.getInt(lastSyncKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  @override
  Future<void> setTestHashes(Map<String, String> hashes) async {
    await _storageService.setString(testHashesKey, json.encode(hashes));
  }

  @override
  Future<Map<String, String>> getTestHashes() async {
    try {
      final hashesJson = _storageService.getString(testHashesKey);
      if (hashesJson == null) return {};
      
      final Map<String, dynamic> decoded = json.decode(hashesJson);
      return decoded.cast<String, String>();
    } catch (e) {
      dev.log('Error reading test hashes: $e');
      return {};
    }
  }

  @override
  Future<List<TestResult>> getUserResults(String userId) async {
    try {
      final key = '$userResultsPrefix$userId';
      final jsonString = _storageService.getString(key);
      if (jsonString == null) return [];
      
      final List<dynamic> decodedJson = json.decode(jsonString);
      return decodedJson.map((item) => TestResult.fromJson(item)).toList();
    } catch (e) {
      dev.log('Error reading user results from storage: $e');
      return [];
    }
  }

  @override
  Future<void> saveUserResults(String userId, List<TestResult> results) async {
    try {
      final key = '$userResultsPrefix$userId';
      final jsonList = results.map((result) => result.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _storageService.setString(key, jsonString);
    } catch (e) {
      dev.log('Error saving user results: $e');
      throw Exception('Failed to save user results: $e');
    }
  }

  @override
  Future<TestResult?> getLatestResult(String userId, String testId) async {
    try {
      final key = '$latestResultPrefix${userId}_$testId';
      final jsonString = _storageService.getString(key);
      if (jsonString == null) return null;
      
      final Map<String, dynamic> data = json.decode(jsonString);
      return TestResult.fromJson(data);
    } catch (e) {
      dev.log('Error reading latest result from storage: $e');
      return null;
    }
  }

  @override
  Future<void> saveTestResult(TestResult result) async {
    try {
      // Save individual result
      final latestKey = '$latestResultPrefix${result.userId}_${result.testId}';
      await _storageService.setString(latestKey, json.encode(result.toJson()));
      
      // Add to user results list
      final userResults = await getUserResults(result.userId);
      
      // Remove any existing result for the same test
      final filteredResults = userResults.where((r) => r.testId != result.testId).toList();
      filteredResults.insert(0, result);
      
      // Keep only recent results (max 50)
      final limitedResults = filteredResults.take(50).toList();
      
      await saveUserResults(result.userId, limitedResults);
    } catch (e) {
      dev.log('Error saving test result: $e');
      throw Exception('Failed to save test result: $e');
    }
  }

  @override
  Future<void> clearUserResults(String userId) async {
    try {
      final userResultsKey = '$userResultsPrefix$userId';
      await _storageService.remove(userResultsKey);
      
      // Remove individual latest results for this user
      final keys = _storageService.getAllKeys();
      final keysToRemove = keys.where((key) => key.startsWith('$latestResultPrefix${userId}_'));
      
      for (final key in keysToRemove) {
        await _storageService.remove(key);
      }
    } catch (e) {
      dev.log('Error clearing user results: $e');
    }
  }

  @override
  Future<void> clearAllResults() async {
    try {
      final keys = _storageService.getAllKeys();
      final resultKeys = keys.where((key) => 
        key.startsWith(userResultsPrefix) || key.startsWith(latestResultPrefix)
      );
      
      for (final key in resultKeys) {
        await _storageService.remove(key);
      }
    } catch (e) {
      dev.log('Error clearing all results: $e');
    }
  }
}