import 'package:korean_language_app/core/enums/test_category.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/features/tests/data/models/test_item.dart';

abstract class TestsRepository {
  // Test management (read-only operations)
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
}