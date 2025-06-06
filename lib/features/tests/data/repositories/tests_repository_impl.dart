import 'dart:developer' as dev;
import 'package:korean_language_app/core/data/base_repository.dart';
import 'package:korean_language_app/core/enums/test_category.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/core/network/network_info.dart';
import 'package:korean_language_app/core/utils/exception_mapper.dart';
import 'package:korean_language_app/features/tests/data/datasources/tests_local_datasource.dart';
import 'package:korean_language_app/features/tests/data/datasources/tests_remote_datasource.dart';
import 'package:korean_language_app/features/tests/data/models/test_item.dart';
import 'package:korean_language_app/features/tests/domain/repositories/tests_repository.dart';

class TestsRepositoryImpl extends BaseRepository implements TestsRepository {
  final TestsRemoteDataSource remoteDataSource;
  final TestsLocalDataSource localDataSource;
  
  static const Duration cacheValidityDuration = Duration(hours: 2);
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(seconds: 1);

  TestsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required NetworkInfo networkInfo,
  }) : super(networkInfo);

  @override
  Future<ApiResult<List<TestItem>>> getTests({int page = 0, int pageSize = 5}) async {
    return _executeWithRetry(() async {
      if (page > 0) {
        if (!await networkInfo.isConnected) {
          throw Exception('No internet connection for pagination');
        }
        return await remoteDataSource.getTests(page: page, pageSize: pageSize);
      }

      if (await _isCacheValid()) {
        final cachedTests = await localDataSource.getAllTests();
        if (cachedTests.isNotEmpty && _areValidTests(cachedTests)) {
          dev.log('Returning ${cachedTests.length} tests from valid cache');
          return cachedTests;
        }
      }

      return await _fetchAndCacheTests(pageSize: pageSize);
    });
  }

  @override
  Future<ApiResult<List<TestItem>>> getTestsByCategory(TestCategory category, {int page = 0, int pageSize = 5}) async {
    return _executeWithRetry(() async {

      if(page > 0) {
        if (!await networkInfo.isConnected) {
          throw Exception('No internet connection for pagination');
        }
        return await remoteDataSource.getTestsByCategory(category, page: page, pageSize: pageSize);
      }

      if(await _isCacheValid()) {
        final cachedTests = await localDataSource.getAllTests();
        final filteredTests = cachedTests.where((test) => test.category == category).toList();
        final validTests =_filterValidTests(filteredTests);
        return validTests;
      }

      final remoteTests = await remoteDataSource.getTestsByCategory(category, page: page, pageSize: pageSize);
      
      if (remoteTests.isNotEmpty) {
        await _updateCacheWithNewTests(remoteTests);
      }
      
      return remoteTests;
    });
  }

  @override
  Future<ApiResult<List<TestItem>>> getTestsFromCache() async {
    try {
      final tests = await localDataSource.getAllTests();
      final validTests = _filterValidTests(tests);
      return ApiResult.success(validTests);
    } catch (e) {
      return ApiResult.failure('Failed to get cached tests: $e', FailureType.cache);
    }
  }

  @override
  Future<ApiResult<bool>> hasMoreTests(int currentCount) async {
    if (!await networkInfo.isConnected) {
      try {
        final totalCached = await localDataSource.getTestsCount();
        return ApiResult.success(currentCount < totalCached);
      } catch (e) {
        return ApiResult.success(false);
      }
    }

    return _executeWithRetry(() async {
      return await remoteDataSource.hasMoreTests(currentCount);
    });
  }

  @override
  Future<ApiResult<bool>> hasMoreTestsByCategory(TestCategory category, int currentCount) async {
    if (!await networkInfo.isConnected) {
      try {
        final cachedTests = await localDataSource.getAllTests();
        final categoryTests = cachedTests.where((test) => test.category == category).length;
        return ApiResult.success(currentCount < categoryTests);
      } catch (e) {
        return ApiResult.success(false);
      }
    }

    return _executeWithRetry(() async {
      return await remoteDataSource.hasMoreTestsByCategory(category, currentCount);
    });
  }

  @override
  Future<ApiResult<List<TestItem>>> hardRefreshTests({int pageSize = 5}) async {
    return _executeWithRetry(() async {
      await _invalidateCache();
      return await _fetchAndCacheTests(pageSize: pageSize);
    });
  }

  @override
  Future<ApiResult<List<TestItem>>> hardRefreshTestsByCategory(TestCategory category, {int pageSize = 5}) async {
    return _executeWithRetry(() async {
      if (!await networkInfo.isConnected) {
        throw Exception('No internet connection for refresh');
      }

      final remoteTests = await remoteDataSource.getTestsByCategory(category, page: 0, pageSize: pageSize);
      
      if (remoteTests.isNotEmpty) {
        await _updateCacheWithNewTests(remoteTests);
      }
      
      return remoteTests;
    });
  }

  @override
  Future<ApiResult<List<TestItem>>> searchTests(String query) async {
    if (query.trim().length < 2) {
      return ApiResult.success([]);
    }

    try {
      final cachedTests = await localDataSource.getAllTests();
      final cachedResults = _searchInTests(cachedTests, query);
      
      if (!await networkInfo.isConnected) {
        return ApiResult.success(cachedResults);
      }

      return await _executeWithRetry(() async {
        final remoteResults = await remoteDataSource.searchTests(query);
        
        if (remoteResults.isNotEmpty) {
          await _updateCacheWithNewTests(remoteResults);
        }
        
        final combinedResults = _combineAndDeduplicateResults(cachedResults, remoteResults);
        return combinedResults;
      });
      
    } catch (e) {
      try {
        final cachedTests = await localDataSource.getAllTests();
        final cachedResults = _searchInTests(cachedTests, query);
        return ApiResult.success(cachedResults);
      } catch (cacheError) {
        return ExceptionMapper.mapExceptionToApiResult(e as Exception);
      }
    }
  }

  @override
  Future<ApiResult<void>> clearCachedTests() async {
    try {
      await localDataSource.clearAllTests();
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure('Failed to clear cache: $e', FailureType.cache);
    }
  }

  @override
  Future<ApiResult<TestItem?>> getTestById(String testId) async {
    try {
      final cachedTests = await localDataSource.getAllTests();
      final cachedTest = cachedTests.where((t) => t.id == testId).firstOrNull;
      
      if (cachedTest != null && await _isCacheValid()) {
        return ApiResult.success(cachedTest);
      }

      if (!await networkInfo.isConnected) {
        return ApiResult.success(cachedTest);
      }

      return await _executeWithRetry(() async {
        final remoteTest = await remoteDataSource.getTestById(testId);
        
        if (remoteTest != null) {
          await localDataSource.updateTest(remoteTest);
          await _updateTestHash(remoteTest);
        }
        
        return remoteTest;
      });
    } catch (e) {
      return ExceptionMapper.mapExceptionToApiResult(e as Exception);
    }
  }

  // Private caching methods
  Future<bool> _isCacheValid() async {
    try {
      final lastSyncTime = await localDataSource.getLastSyncTime();
      if (lastSyncTime == null) return false;
      
      final cacheAge = DateTime.now().difference(lastSyncTime);
      return cacheAge < cacheValidityDuration;
    } catch (e) {
      return false;
    }
  }

  Future<void> _invalidateCache() async {
    await localDataSource.clearAllTests();
  }

  Future<List<TestItem>> _fetchAndCacheTests({required int pageSize}) async {
    if (!await networkInfo.isConnected) {
      final cachedTests = await localDataSource.getAllTests();
      if (cachedTests.isNotEmpty) {
        return _filterValidTests(cachedTests);
      }
      throw Exception('No internet connection and no cached data');
    }

    final remoteTests = await remoteDataSource.getTests(page: 0, pageSize: pageSize);
    
    final deletedIds = await _getDeletedTestIds(remoteTests);
    for (final deletedId in deletedIds) {
      await localDataSource.removeTest(deletedId);
    }
    
    await _cacheTests(remoteTests);
    
    return remoteTests;
  }

  Future<void> _cacheTests(List<TestItem> tests) async {
    try {
      final existingTests = await localDataSource.getAllTests();
      final mergedTests = _mergeTests(existingTests, tests);
      
      await localDataSource.saveTests(mergedTests);
      await _updateLastSyncTime();
      await _updateTestsHashes(mergedTests);
    } catch (e) {
      dev.log('Failed to cache tests: $e');
    }
  }

  Future<void> _updateCacheWithNewTests(List<TestItem> newTests) async {
    try {
      for (final test in newTests) {
        await localDataSource.addTest(test);
        await _updateTestHash(test);
      }
    } catch (e) {
      dev.log('Failed to update cache with new tests: $e');
    }
  }

  Future<void> _updateLastSyncTime() async {
    await localDataSource.setLastSyncTime(DateTime.now());
  }

  Future<void> _updateTestsHashes(List<TestItem> tests) async {
    final hashes = <String, String>{};
    for (final test in tests) {
      hashes[test.id] = _generateTestHash(test);
    }
    await localDataSource.setTestHashes(hashes);
  }

  Future<void> _updateTestHash(TestItem test) async {
    final currentHashes = await localDataSource.getTestHashes();
    currentHashes[test.id] = _generateTestHash(test);
    await localDataSource.setTestHashes(currentHashes);
  }

  Future<List<String>> _getDeletedTestIds(List<TestItem> remoteTests) async {
    try {
      final cachedTests = await localDataSource.getAllTests();
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

  List<TestItem> _searchInTests(List<TestItem> tests, String query) {
    final normalizedQuery = query.toLowerCase();
    
    return tests.where((test) {
      return test.title.toLowerCase().contains(normalizedQuery) ||
             test.description.toLowerCase().contains(normalizedQuery) ||
             test.language.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  List<TestItem> _combineAndDeduplicateResults(
    List<TestItem> cachedTests,
    List<TestItem> remoteTests,
  ) {
    final Map<String, TestItem> uniqueTests = {};
    
    for (final test in cachedTests) {
      uniqueTests[test.id] = test;
    }
    
    for (final test in remoteTests) {
      uniqueTests[test.id] = test;
    }
    
    return uniqueTests.values.toList();
  }

  List<TestItem> _filterValidTests(List<TestItem> tests) {
    return tests.where((test) => 
      test.id.isNotEmpty && 
      test.title.isNotEmpty && 
      test.description.isNotEmpty &&
      test.questions.isNotEmpty
    ).toList();
  }

  bool _areValidTests(List<TestItem> tests) {
    return tests.every((test) => 
      test.id.isNotEmpty && 
      test.title.isNotEmpty && 
      test.description.isNotEmpty &&
      test.questions.isNotEmpty
    );
  }

  String _generateTestHash(TestItem test) {
    final content = '${test.title}_${test.description}_${test.questions.length}_${test.updatedAt?.millisecondsSinceEpoch ?? 0}';
    return content.hashCode.toString();
  }

  Future<ApiResult<T>> _executeWithRetry<T>(Future<T> Function() operation) async {
    Exception? lastException;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final result = await operation();
        return ApiResult.success(result);
      } catch (e) {
        lastException = e as Exception;
        
        if (attempt == maxRetries) {
          break;
        }
        
        final delay = Duration(seconds: initialRetryDelay.inSeconds * attempt);
        await Future.delayed(delay);
        
        dev.log('Retry attempt $attempt failed: $e. Retrying in ${delay.inSeconds}s...');
      }
    }
    
    return ExceptionMapper.mapExceptionToApiResult(lastException!);
  }
}