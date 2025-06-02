import 'dart:convert';
import 'dart:developer' as dev;
import 'package:korean_language_app/features/tests/data/datasources/tests_local_datasource.dart';
import 'package:korean_language_app/features/tests/data/models/test_item.dart';
import 'package:korean_language_app/features/tests/data/models/test_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/cache_health_status.dart';

class TestsLocalDataSourceImpl implements TestsLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String testsKey = 'CACHED_TESTS';
  static const String lastSyncKey = 'LAST_TESTS_SYNC_TIME';
  static const String testHashesKey = 'TEST_HASHES';
  static const String userResultsPrefix = 'USER_RESULTS_';
  static const String latestResultPrefix = 'LATEST_RESULT_';
  
  static const Duration cacheValidityDuration = Duration(hours: 2);

  TestsLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<TestItem>> getCachedTests() async {
    try {
      final jsonString = sharedPreferences.getString(testsKey);
      if (jsonString == null) return [];
      
      final List<dynamic> decodedJson = json.decode(jsonString);
      final tests = decodedJson.map((item) => TestItem.fromJson(item)).toList();
      
      final validTests = tests.where((test) => 
        test.id.isNotEmpty && 
        test.title.isNotEmpty && 
        test.description.isNotEmpty &&
        test.questions.isNotEmpty
      ).toList();
      
      if (validTests.length != tests.length) {
        await _saveTestsToCache(validTests);
      }
      
      return validTests;
    } catch (e) {
      dev.log('Error reading cached tests: $e');
      await clearCachedTests();
      return [];
    }
  }

  @override
  Future<void> cacheTests(List<TestItem> tests) async {
    if (tests.isEmpty) return;
    
    try {
      final existingTests = await getCachedTests();
      final mergedTests = _mergeTests(existingTests, tests);
      await _saveTestsToCache(mergedTests);
      
      await sharedPreferences.setInt(lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      await _updateTestHashes(mergedTests);
      
    } catch (e) {
      dev.log('Error caching tests: $e');
      throw Exception('Failed to cache tests: $e');
    }
  }

  @override
  Future<bool> hasAnyCachedTests() async {
    try {
      final tests = await getCachedTests();
      return tests.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> getCachedTestsCount() async {
    try {
      final tests = await getCachedTests();
      return tests.length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<void> clearCachedTests() async {
    try {
      await sharedPreferences.remove(testsKey);
      await sharedPreferences.remove(lastSyncKey);
      await sharedPreferences.remove(testHashesKey);
    } catch (e) {
      dev.log('Error clearing tests cache: $e');
    }
  }

  @override
  Future<void> updateTestMetadata(TestItem test) async {
    try {
      final existingTests = await getCachedTests();
      final testIndex = existingTests.indexWhere((t) => t.id == test.id);
      
      if (testIndex != -1) {
        existingTests[testIndex] = test;
      } else {
        existingTests.add(test);
      }
      
      await _saveTestsToCache(existingTests);
      await _updateTestHashes(existingTests);
    } catch (e) {
      dev.log('Error updating test metadata: $e');
      throw Exception('Failed to update test metadata: $e');
    }
  }

  @override
  Future<void> removeTestFromCache(String testId) async {
    try {
      final existingTests = await getCachedTests();
      final updatedTests = existingTests.where((test) => test.id != testId).toList();
      
      await _saveTestsToCache(updatedTests);
      await _updateTestHashes(updatedTests);
    } catch (e) {
      dev.log('Error removing test from cache: $e');
      throw Exception('Failed to remove test from cache: $e');
    }
  }

  @override
  Future<bool> isCacheValid() async {
    try {
      final lastSyncTimestamp = sharedPreferences.getInt(lastSyncKey);
      if (lastSyncTimestamp == null) return false;
      
      final lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncTimestamp);
      final cacheAge = DateTime.now().difference(lastSync);
      
      return cacheAge < cacheValidityDuration;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> invalidateCache() async {
    await sharedPreferences.remove(lastSyncKey);
  }

  @override
  Future<List<String>> getDeletedTestIds(List<TestItem> remoteTests) async {
    try {
      final cachedTests = await getCachedTests();
      final remoteTestIds = remoteTests.map((test) => test.id).toSet();
      
      final deletedIds = cachedTests
          .where((test) => !remoteTestIds.contains(test.id))
          .map((test) => test.id)
          .toList();
      
      return deletedIds;
    } catch (e) {
      dev.log('Error detecting deleted tests: $e');
      return [];
    }
  }

  @override
  Future<bool> hasTestChanged(TestItem test) async {
    try {
      final hashesJson = sharedPreferences.getString(testHashesKey);
      if (hashesJson == null) return true;
      
      final Map<String, dynamic> hashes = json.decode(hashesJson);
      final currentHash = _generateTestHash(test);
      final storedHash = hashes[test.id];
      
      return currentHash != storedHash;
    } catch (e) {
      return true;
    }
  }

  @override
  Future<void> markTestAsSynced(TestItem test) async {
    try {
      final hashesJson = sharedPreferences.getString(testHashesKey);
      final Map<String, dynamic> hashes = hashesJson != null 
          ? json.decode(hashesJson)
          : <String, dynamic>{};
      
      hashes[test.id] = _generateTestHash(test);
      
      await sharedPreferences.setString(testHashesKey, json.encode(hashes));
    } catch (e) {
      dev.log('Error marking test as synced: $e');
    }
  }

  @override
  Future<CacheHealthStatus> checkCacheHealth() async {
    try {
      final tests = await getCachedTests();
      final isValid = await isCacheValid();
      final hasCorruptedEntries = tests.any((test) => 
        test.id.isEmpty || test.title.isEmpty || test.description.isEmpty || test.questions.isEmpty
      );
      
      final resultsCount = await _getCachedResultsCount();
      
      return CacheHealthStatus(
        isValid: isValid,
        testsCount: tests.length,
        resultsCount: resultsCount,
        hasCorruptedEntries: hasCorruptedEntries,
        lastSyncTime: DateTime.fromMillisecondsSinceEpoch(
          sharedPreferences.getInt(lastSyncKey) ?? 0
        ),
      );
    } catch (e) {
      return CacheHealthStatus(
        isValid: false,
        testsCount: 0,
        resultsCount: 0,
        hasCorruptedEntries: true,
        lastSyncTime: null,
      );
    }
  }

  // Test Results methods
  @override
  Future<List<TestResult>> getCachedUserResults(String userId) async {
    try {
      final key = '$userResultsPrefix$userId';
      final jsonString = sharedPreferences.getString(key);
      if (jsonString == null) return [];
      
      final List<dynamic> decodedJson = json.decode(jsonString);
      final results = decodedJson.map((item) => TestResult.fromJson(item)).toList();
      
      return results;
    } catch (e) {
      dev.log('Error reading cached user results: $e');
      return [];
    }
  }

  @override
  Future<void> cacheUserResults(String userId, List<TestResult> results) async {
    try {
      final key = '$userResultsPrefix$userId';
      final jsonList = results.map((result) => result.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await sharedPreferences.setString(key, jsonString);
    } catch (e) {
      dev.log('Error caching user results: $e');
    }
  }

  @override
  Future<TestResult?> getCachedLatestResult(String userId, String testId) async {
    try {
      final key = '$latestResultPrefix${userId}_$testId';
      final jsonString = sharedPreferences.getString(key);
      if (jsonString == null) return null;
      
      final Map<String, dynamic> data = json.decode(jsonString);
      return TestResult.fromJson(data);
    } catch (e) {
      dev.log('Error reading cached latest result: $e');
      return null;
    }
  }

  @override
  Future<void> cacheTestResult(TestResult result) async {
    try {
      // Cache individual result
      final latestKey = '$latestResultPrefix${result.userId}_${result.testId}';
      await sharedPreferences.setString(latestKey, json.encode(result.toJson()));
      
      // Add to user results list
      final userResults = await getCachedUserResults(result.userId);
      
      // Remove any existing result for the same test
      final filteredResults = userResults.where((r) => r.testId != result.testId).toList();
      filteredResults.insert(0, result);
      
      // Keep only recent results (max 50)
      final limitedResults = filteredResults.take(50).toList();
      
      await cacheUserResults(result.userId, limitedResults);
    } catch (e) {
      dev.log('Error caching test result: $e');
    }
  }

  @override
  Future<void> clearCachedResults(String userId) async {
    try {
      final userResultsKey = '$userResultsPrefix$userId';
      await sharedPreferences.remove(userResultsKey);
      
      // Remove individual latest results for this user
      final keys = sharedPreferences.getKeys();
      final keysToRemove = keys.where((key) => key.startsWith('$latestResultPrefix${userId}_'));
      
      for (final key in keysToRemove) {
        await sharedPreferences.remove(key);
      }
    } catch (e) {
      dev.log('Error clearing cached results: $e');
    }
  }

  // Helper methods
  Future<void> _saveTestsToCache(List<TestItem> tests) async {
    final jsonList = tests.map((test) => test.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await sharedPreferences.setString(testsKey, jsonString);
  }

  List<TestItem> _mergeTests(List<TestItem> existing, List<TestItem> newTests) {
    final Map<String, TestItem> testMap = {};
    
    for (final test in existing) {
      testMap[test.id] = test;
    }
    
    for (final test in newTests) {
      testMap[test.id] = test;
    }
    
    final mergedTests = testMap.values.toList();
    mergedTests.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
    
    return mergedTests;
  }

  Future<void> _updateTestHashes(List<TestItem> tests) async {
    try {
      final Map<String, String> hashes = {};
      for (final test in tests) {
        hashes[test.id] = _generateTestHash(test);
      }
      
      await sharedPreferences.setString(testHashesKey, json.encode(hashes));
    } catch (e) {
      dev.log('Error updating test hashes: $e');
    }
  }

  String _generateTestHash(TestItem test) {
    final content = '${test.title}_${test.description}_${test.questions.length}_${test.updatedAt?.millisecondsSinceEpoch ?? 0}';
    return content.hashCode.toString();
  }

  Future<int> _getCachedResultsCount() async {
    try {
      final keys = sharedPreferences.getKeys();
      final resultKeys = keys.where((key) => key.startsWith(userResultsPrefix));
      
      int totalCount = 0;
      for (final key in resultKeys) {
        final jsonString = sharedPreferences.getString(key);
        if (jsonString != null) {
          final List<dynamic> decodedJson = json.decode(jsonString);
          totalCount += decodedJson.length;
        }
      }
      
      return totalCount;
    } catch (e) {
      return 0;
    }
  }
}