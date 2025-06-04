import 'dart:io';
import 'package:korean_language_app/core/enums/test_category.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/features/tests/data/models/test_item.dart';
import 'package:korean_language_app/features/tests/data/models/test_result.dart';

abstract class TestsRepository {
  // Test management
  Future<ApiResult<List<TestItem>>> getTests({int page = 0, int pageSize = 5});
  Future<ApiResult<List<TestItem>>> getTestsByCategory(TestCategory category, {int page = 0, int pageSize = 5});
  Future<ApiResult<bool>> hasMoreTests(int currentCount);
  Future<ApiResult<bool>> hasMoreTestsByCategory(TestCategory category, int currentCount);
  Future<ApiResult<List<TestItem>>> hardRefreshTests({int pageSize = 5});
  Future<ApiResult<List<TestItem>>> hardRefreshTestsByCategory(TestCategory category, {int pageSize = 5});
  Future<ApiResult<List<TestItem>>> getTestsFromCache();
  Future<ApiResult<List<TestItem>>> searchTests(String query);
  Future<ApiResult<void>> clearCachedTests();
  Future<ApiResult<TestItem?>> getTestById(String testId);
  
  // Test CRUD operations (admin)
  Future<ApiResult<TestItem>> createTest(TestItem test);
  Future<ApiResult<bool>> updateTest(String testId, TestItem updatedTest);
  Future<ApiResult<bool>> deleteTest(String testId);
  Future<ApiResult<String?>> uploadTestImage(String testId, File imageFile);
  Future<ApiResult<String?>> regenerateImageUrl(TestItem test);
  
  // Permission checks
  Future<ApiResult<bool>> hasEditPermission(String testId, String userId);
  Future<ApiResult<bool>> hasDeletePermission(String testId, String userId);
  
  // Test results
  Future<ApiResult<bool>> saveTestResult(TestResult result);
  Future<ApiResult<List<TestResult>>> getUserTestResults(String userId, {int limit = 20});
  Future<ApiResult<List<TestResult>>> getTestResults(String testId, {int limit = 50});
  Future<ApiResult<TestResult?>> getUserLatestResult(String userId, String testId);
  Future<ApiResult<List<TestResult>>> getCachedUserResults(String userId);
}