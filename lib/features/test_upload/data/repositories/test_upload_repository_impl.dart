import 'dart:developer' as dev;
import 'dart:io';
import 'package:korean_language_app/core/data/base_repository.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/core/network/network_info.dart';
import 'package:korean_language_app/core/utils/exception_mapper.dart';
import 'package:korean_language_app/features/admin/data/service/admin_permission.dart';
import 'package:korean_language_app/features/test_upload/data/datasources/test_upload_remote_datasource.dart';
import 'package:korean_language_app/features/test_upload/domain/test_upload_repository.dart';
import 'package:korean_language_app/features/tests/data/models/test_item.dart';

class TestUploadRepositoryImpl extends BaseRepository implements TestUploadRepository {
  final TestUploadRemoteDataSource remoteDataSource;
  final AdminPermissionService adminService;
  
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(seconds: 1);

  TestUploadRepositoryImpl({
    required this.remoteDataSource,
    required this.adminService,
    required NetworkInfo networkInfo,
  }) : super(networkInfo);

  @override
  Future<ApiResult<TestItem>> createTest(TestItem test) async {
    if (!await networkInfo.isConnected) {
      return ApiResult.failure('No internet connection', FailureType.network);
    }

    return _executeWithRetry(() async {
      final updatedTest = await remoteDataSource.uploadTest(test);
      return updatedTest;
    });
  }

  @override
  Future<ApiResult<bool>> updateTest(String testId, TestItem updatedTest) async {
    if (!await networkInfo.isConnected) {
      return ApiResult.failure('No internet connection', FailureType.network);
    }

    return _executeWithRetry(() async {
      final success = await remoteDataSource.updateTest(testId, updatedTest);
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
          await remoteDataSource.updateTest(test.id, updatedTest);
        } catch (e) {
          dev.log('Failed to update test with new image URL: $e');
        }
      }
      
      return newUrl;
    });
  }

  @override
  Future<ApiResult<bool>> hasEditPermission(String testId, String userId) async {
    try {
      if (await adminService.isUserAdmin(userId)) {
        return ApiResult.success(true);
      }
      
      // Note: This would need access to test data to check creatorUid
      // For now, returning false for non-admin users
      // You might want to add a method to get test creator info
      return ApiResult.success(false);
    } catch (e) {
      return ApiResult.failure('Error checking edit permission: $e');
    }
  }

  @override
  Future<ApiResult<bool>> hasDeletePermission(String testId, String userId) async {
    return hasEditPermission(testId, userId);
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