import 'dart:io';
import 'package:korean_language_app/core/enums/test_category.dart';
import 'package:korean_language_app/features/tests/data/models/test_item.dart';
import 'package:korean_language_app/features/tests/data/models/test_result.dart';

abstract class TestsRemoteDataSource {
  Future<List<TestItem>> getTests({int page = 0, int pageSize = 5});
  Future<List<TestItem>> getTestsByCategory(TestCategory category, {int page = 0, int pageSize = 5});
  Future<bool> hasMoreTests(int currentCount);
  Future<bool> hasMoreTestsByCategory(TestCategory category, int currentCount);
  Future<List<TestItem>> searchTests(String query);
  Future<TestItem?> getTestById(String testId);
  Future<TestItem> uploadTest(TestItem test);
  Future<bool> updateTest(String testId, TestItem updatedTest);
  Future<bool> deleteTest(String testId);
  Future<(String, String)?> uploadTestImage(String testId, File imageFile);
  Future<DateTime?> getTestLastUpdated(String testId);
  Future<String?> regenerateUrlFromPath(String storagePath);
  Future<bool> verifyUrlIsWorking(String url);
  
  // Test results
  Future<bool> saveTestResult(TestResult result);
  Future<List<TestResult>> getUserTestResults(String userId, {int limit = 20});
  Future<List<TestResult>> getTestResults(String testId, {int limit = 50});
  Future<TestResult?> getUserLatestResult(String userId, String testId);
}