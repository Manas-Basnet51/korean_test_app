import 'dart:developer' as dev;
import 'package:korean_language_app/core/data/base_repository.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/core/network/network_info.dart';
import 'package:korean_language_app/core/utils/exception_mapper.dart';
import 'package:korean_language_app/features/test_results/data/datasources/test_results_local_datasources.dart';
import 'package:korean_language_app/features/test_results/data/datasources/test_results_remote_datasources.dart';
import 'package:korean_language_app/features/test_results/data/models/test_result.dart';
import 'package:korean_language_app/features/test_results/domain/repositories/test_results_repository.dart';

class TestResultsRepositoryImpl extends BaseRepository implements TestResultsRepository {
  final TestResultsRemoteDataSource remoteDataSource;
  final TestResultsLocalDataSource localDataSource;
  
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(seconds: 1);

  TestResultsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required NetworkInfo networkInfo,
  }) : super(networkInfo);

  @override
  Future<ApiResult<bool>> saveTestResult(TestResult result) async {
    try {
      await localDataSource.saveTestResult(result);
      
      if (!await networkInfo.isConnected) {
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

  @override
  Future<ApiResult<void>> clearUserResults(String userId) async {
    try {
      await localDataSource.clearUserResults(userId);
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure('Failed to clear user results: $e', FailureType.cache);
    }
  }

  @override
  Future<ApiResult<void>> clearAllResults() async {
    try {
      await localDataSource.clearAllResults();
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure('Failed to clear all results: $e', FailureType.cache);
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