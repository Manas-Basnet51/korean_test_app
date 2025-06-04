import 'dart:developer' as dev;
import 'dart:io';
import 'package:korean_language_app/core/data/base_repository.dart';
import 'package:korean_language_app/core/enums/test_category.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/core/network/network_info.dart';
import 'package:korean_language_app/core/utils/exception_mapper.dart';
import 'package:korean_language_app/features/admin/data/service/admin_permission.dart';
import 'package:korean_language_app/features/tests/data/datasources/tests_local_datasource.dart';
import 'package:korean_language_app/features/tests/data/datasources/tests_remote_datasource.dart';
import 'package:korean_language_app/features/tests/data/models/test_item.dart';
import 'package:korean_language_app/features/tests/data/models/test_result.dart';
import 'package:korean_language_app/features/tests/domain/repositories/tests_repository.dart';

class TestsRepositoryImpl extends BaseRepository implements TestsRepository {
  final TestsRemoteDataSource remoteDataSource;
  final TestsLocalDataSource localDataSource;
  final AdminPermissionService adminService;
  
  // Caching configuration
  static const Duration cacheValidityDuration = Duration(hours: 2);
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(seconds: 1);

  TestsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.adminService,
    required NetworkInfo networkInfo,
  }) : super(networkInfo);

  @override
  Future<ApiResult<List<TestItem>>> getTests({int page = 0, int pageSize = 5}) async {
    return _executeWithRetry(() async {
      // For pagination beyond first page, always fetch from remote
      if (page > 0) {
        if (!await networkInfo.isConnected) {
          throw Exception('No internet connection for pagination');
        }
        return await remoteDataSource.getTests(page: page, pageSize: pageSize);
      }

      // Check cache validity for first page
      if (await _isCacheValid()) {
        final cachedTests = await localDataSource.getAllTests();
        if (cachedTests.isNotEmpty && _areValidTests(cachedTests)) {
          dev.log('Returning ${cachedTests.length} tests from valid cache');
          return cachedTests;
        }
      }

      // Fetch from remote and cache
      return await _fetchAndCacheTests(pageSize: pageSize);
    });
  }

  @override
  Future<ApiResult<List<TestItem>>> getTestsByCategory(TestCategory category, {int page = 0, int pageSize = 5}) async {
    return _executeWithRetry(() async {
      if (!await networkInfo.isConnected) {
        // Try to return cached data filtered by category
        final cachedTests = await localDataSource.getAllTests();
        final filteredTests = cachedTests.where((test) => test.category == category).toList();
        return _filterValidTests(filteredTests);
      }

      final remoteTests = await remoteDataSource.getTestsByCategory(category, page: page, pageSize: pageSize);
      
      // Update cache with new tests
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
  Future<ApiResult<List<TestItem>>> hardRefreshTests({int pageSize = 5}) async {
    return _executeWithRetry(() async {
      await _invalidateCache();
      return await _fetchAndCacheTests(pageSize: pageSize);
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
      // First check cache
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

  // Test CRUD operations
  @override
  Future<ApiResult<bool>> createTest(TestItem test) async {
    if (!await networkInfo.isConnected) {
      return ApiResult.failure('No internet connection', FailureType.network);
    }

    return _executeWithRetry(() async {
      final success = await remoteDataSource.uploadTest(test);
      
      if (success) {
        try {
          await localDataSource.addTest(test);
          await _updateTestHash(test);
          await _updateLastSyncTime();
        } catch (e) {
          dev.log('Failed to cache after create: $e');
        }
      }
      
      return success;
    });
  }

  @override
  Future<ApiResult<bool>> updateTest(String testId, TestItem updatedTest) async {
    if (!await networkInfo.isConnected) {
      return ApiResult.failure('No internet connection', FailureType.network);
    }

    return _executeWithRetry(() async {
      final success = await remoteDataSource.updateTest(testId, updatedTest);
      
      if (success) {
        try {
          await localDataSource.updateTest(updatedTest);
          await _updateTestHash(updatedTest);
        } catch (e) {
          dev.log('Failed to update local cache: $e');
        }
      }
      
      return success;
    });
  }

  @override
  Future<ApiResult<bool>> deleteTest(String testId) async {
    if (!await networkInfo.isConnected) {
      return ApiResult.failure('No internet connection', FailureType.network);
    }

    return _executeWithRetry(() async {
      final success = await remoteDataSource.deleteTest(testId);
      
      if (success) {
        try {
          await localDataSource.removeTest(testId);
          await _removeTestHash(testId);
        } catch (e) {
          dev.log('Failed to remove from cache: $e');
        }
      }
      
      return success;
    });
  }

  @override
  Future<ApiResult<String?>> uploadTestImage(String testId, File imageFile) async {
    if (!await networkInfo.isConnected) {
      return ApiResult.failure('No internet connection', FailureType.network);
    }

    return _executeWithRetry(() async {
      final uploadData = await remoteDataSource.uploadTestImage(testId, imageFile);
      if (uploadData == null) return null;
      
      final imageUrl = uploadData.$1;
      final imagePath = uploadData.$2;
      
      try {
        await _updateTestImageInCache(testId, imageUrl, imagePath);
      } catch (e) {
        dev.log('Failed to update cache with new image: $e');
      }
      
      return imageUrl;
    });
  }

  @override
  Future<ApiResult<String?>> regenerateImageUrl(TestItem test) async {
    if (test.imagePath == null || test.imagePath!.isEmpty) {
      return ApiResult.success(null);
    }

    if (!await networkInfo.isConnected) {
      return ApiResult.failure('No internet connection', FailureType.network);
    }

    return _executeWithRetry(() async {
      final newUrl = await remoteDataSource.regenerateUrlFromPath(test.imagePath!);
      
      if (newUrl != null && newUrl.isNotEmpty) {
        final updatedTest = test.copyWith(imageUrl: newUrl);
        
        try {
          await localDataSource.updateTest(updatedTest);
          await remoteDataSource.updateTest(test.id, updatedTest);
          await _updateTestHash(updatedTest);
        } catch (e) {
          dev.log('Failed to update test with new image URL: $e');
        }
      }
      
      return newUrl;
    });
  }

  // Permission checks
  @override
  Future<ApiResult<bool>> hasEditPermission(String testId, String userId) async {
    try {
      if (await adminService.isUserAdmin(userId)) {
        return ApiResult.success(true);
      }
      
      final test = await remoteDataSource.getTestById(testId);
      if (test != null && test.creatorUid == userId) {
        return ApiResult.success(true);
      }
      
      return ApiResult.success(false);
    } catch (e) {
      return ApiResult.failure('Error checking edit permission: $e');
    }
  }

  @override
  Future<ApiResult<bool>> hasDeletePermission(String testId, String userId) async {
    return hasEditPermission(testId, userId);
  }

  // Test results
  @override
  Future<ApiResult<bool>> saveTestResult(TestResult result) async {
    try {
      // Always cache locally first
      await localDataSource.saveTestResult(result);
      
      if (!await networkInfo.isConnected) {
        // Will be synced when connection is restored
        return ApiResult.success(true);
      }

      return _executeWithRetry(() async {
        return await remoteDataSource.saveTestResult(result);
      });
    } catch (e) {
      return ExceptionMapper.mapExceptionToApiResult(e as Exception);
    }
  }

  @override
  Future<ApiResult<List<TestResult>>> getUserTestResults(String userId, {int limit = 20}) async {
    try {
      final cachedResults = await localDataSource.getUserResults(userId);
      
      if (!await networkInfo.isConnected) {
        return ApiResult.success(cachedResults);
      }

      return await _executeWithRetry(() async {
        final remoteResults = await remoteDataSource.getUserTestResults(userId, limit: limit);
        
        if (remoteResults.isNotEmpty) {
          await localDataSource.saveUserResults(userId, remoteResults);
        }
        
        return remoteResults.isNotEmpty ? remoteResults : cachedResults;
      });
    } catch (e) {
      try {
        final cachedResults = await localDataSource.getUserResults(userId);
        return ApiResult.success(cachedResults);
      } catch (cacheError) {
        return ExceptionMapper.mapExceptionToApiResult(e as Exception);
      }
    }
  }

  @override
  Future<ApiResult<List<TestResult>>> getTestResults(String testId, {int limit = 50}) async {
    if (!await networkInfo.isConnected) {
      return ApiResult.failure('No internet connection', FailureType.network);
    }

    return _executeWithRetry(() async {
      return await remoteDataSource.getTestResults(testId, limit: limit);
    });
  }

  @override
  Future<ApiResult<TestResult?>> getUserLatestResult(String userId, String testId) async {
    try {
      final cachedResult = await localDataSource.getLatestResult(userId, testId);
      
      if (!await networkInfo.isConnected) {
        return ApiResult.success(cachedResult);
      }

      return await _executeWithRetry(() async {
        final remoteResult = await remoteDataSource.getUserLatestResult(userId, testId);
        
        if (remoteResult != null) {
          await localDataSource.saveTestResult(remoteResult);
        }
        
        return remoteResult ?? cachedResult;
      });
    } catch (e) {
      try {
        final cachedResult = await localDataSource.getLatestResult(userId, testId);
        return ApiResult.success(cachedResult);
      } catch (cacheError) {
        return ExceptionMapper.mapExceptionToApiResult(e as Exception);
      }
    }
  }

  @override
  Future<ApiResult<List<TestResult>>> getCachedUserResults(String userId) async {
    try {
      final results = await localDataSource.getUserResults(userId);
      return ApiResult.success(results);
    } catch (e) {
      return ApiResult.failure('Failed to get cached results: $e', FailureType.cache);
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
    
    // Detect deleted tests for cache sync
    final deletedIds = await _getDeletedTestIds(remoteTests);
    for (final deletedId in deletedIds) {
      await localDataSource.removeTest(deletedId);
    }
    
    // Cache new/updated tests
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

  Future<void> _removeTestHash(String testId) async {
    final currentHashes = await localDataSource.getTestHashes();
    currentHashes.remove(testId);
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

  Future<void> _updateTestImageInCache(String testId, String imageUrl, String imagePath) async {
    try {
      final tests = await localDataSource.getAllTests();
      final test = tests.firstWhere((t) => t.id == testId);
      
      final updatedTest = test.copyWith(
        imageUrl: imageUrl,
        imagePath: imagePath,
      );
      
      await localDataSource.updateTest(updatedTest);
      await remoteDataSource.updateTest(testId, updatedTest);
      await _updateTestHash(updatedTest);
    } catch (e) {
      dev.log('Error updating test image in cache: $e');
    }
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