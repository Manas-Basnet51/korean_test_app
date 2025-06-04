import 'package:korean_language_app/features/tests/data/models/test_item.dart';
import 'package:korean_language_app/features/tests/data/models/test_result.dart';

abstract class TestsLocalDataSource {
  // Basic test operations
  Future<List<TestItem>> getAllTests();
  Future<void> saveTests(List<TestItem> tests);
  Future<void> addTest(TestItem test);
  Future<void> updateTest(TestItem test);
  Future<void> removeTest(String testId);
  Future<void> clearAllTests();
  Future<bool> hasAnyTests();
  Future<int> getTestsCount();
  
  // metadata operations
  Future<void> setLastSyncTime(DateTime dateTime);
  Future<DateTime?> getLastSyncTime();
  Future<void> setTestHashes(Map<String, String> hashes);
  Future<Map<String, String>> getTestHashes();
  
  // Test results operations
  Future<List<TestResult>> getUserResults(String userId);
  Future<void> saveUserResults(String userId, List<TestResult> results);
  Future<TestResult?> getLatestResult(String userId, String testId);
  Future<void> saveTestResult(TestResult result);
  Future<void> clearUserResults(String userId);
  Future<void> clearAllResults();
}