import 'package:korean_language_app/features/tests/data/models/test_item.dart';
import 'package:korean_language_app/features/tests/data/models/test_result.dart';

import '../../domain/entities/cache_health_status.dart';

abstract class TestsLocalDataSource {
  Future<List<TestItem>> getCachedTests();
  Future<void> cacheTests(List<TestItem> tests);
  Future<bool> hasAnyCachedTests();
  Future<int> getCachedTestsCount();
  Future<void> clearCachedTests();
  Future<void> updateTestMetadata(TestItem test);
  Future<void> removeTestFromCache(String testId);
  
  Future<bool> isCacheValid();
  Future<void> invalidateCache();
  Future<List<String>> getDeletedTestIds(List<TestItem> remoteTests);
  Future<bool> hasTestChanged(TestItem test);
  Future<void> markTestAsSynced(TestItem test);
  Future<CacheHealthStatus> checkCacheHealth();
  
  // Test results caching
  Future<List<TestResult>> getCachedUserResults(String userId);
  Future<void> cacheUserResults(String userId, List<TestResult> results);
  Future<TestResult?> getCachedLatestResult(String userId, String testId);
  Future<void> cacheTestResult(TestResult result);
  Future<void> clearCachedResults(String userId);
}

