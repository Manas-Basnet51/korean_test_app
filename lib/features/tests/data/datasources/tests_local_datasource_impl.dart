import 'dart:convert';
import 'dart:developer' as dev;
import 'package:korean_language_app/core/services/storage_service.dart';
import 'package:korean_language_app/features/tests/data/datasources/tests_local_datasource.dart';
import 'package:korean_language_app/core/models/test_item.dart';

class TestsLocalDataSourceImpl implements TestsLocalDataSource {
  final StorageService _storageService;
  static const String testsKey = 'CACHED_TESTS';
  static const String lastSyncKey = 'LAST_TESTS_SYNC_TIME';
  static const String testHashesKey = 'TEST_HASHES';

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
}