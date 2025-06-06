import 'package:korean_language_app/features/test_results/data/models/test_result.dart';

abstract class TestResultsRemoteDataSource {
  Future<bool> saveTestResult(TestResult result);
  Future<List<TestResult>> getUserTestResults(String userId, {int limit = 20});
  Future<List<TestResult>> getTestResults(String testId, {int limit = 50});
  Future<TestResult?> getUserLatestResult(String userId, String testId);
}