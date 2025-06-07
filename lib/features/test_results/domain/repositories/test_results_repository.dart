import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/core/models/test_result.dart';

abstract class TestResultsRepository {
  // Save test results
  Future<ApiResult<bool>> saveTestResult(TestResult result);
  
  // Get user test results
  Future<ApiResult<List<TestResult>>> getUserTestResults(String userId, {int limit = 20});
  Future<ApiResult<List<TestResult>>> getCachedUserResults(String userId);
  
  // Get test results for a specific test
  Future<ApiResult<List<TestResult>>> getTestResults(String testId, {int limit = 50});
  
  // Get latest result for a user and test
  Future<ApiResult<TestResult?>> getUserLatestResult(String userId, String testId);
  
  // Clear user results
  Future<ApiResult<void>> clearUserResults(String userId);
  Future<ApiResult<void>> clearAllResults();
}