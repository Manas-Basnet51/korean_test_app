import 'dart:io';
import 'package:korean_language_app/core/data/base_repository.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/core/network/network_info.dart';
import 'package:korean_language_app/features/admin/data/service/admin_permission.dart';
import 'package:korean_language_app/features/test_upload/data/datasources/test_upload_remote_datasource.dart';
import 'package:korean_language_app/features/test_upload/domain/test_upload_repository.dart';
import 'package:korean_language_app/features/tests/data/models/test_item.dart';

class TestUploadRepositoryImpl extends BaseRepository implements TestUploadRepository {
  final TestUploadRemoteDataSource remoteDataSource;
  final AdminPermissionService adminService;

  TestUploadRepositoryImpl({
    required this.remoteDataSource,
    required this.adminService,
    required NetworkInfo networkInfo,
  }) : super(networkInfo);

  @override
  Future<ApiResult<TestItem>> createTest(TestItem test) async {
    return handleRepositoryCall(() async {
      final updatedTest = await remoteDataSource.uploadTest(test);
      return ApiResult.success(updatedTest);
    });
  }

  @override
  Future<ApiResult<bool>> updateTest(String testId, TestItem updatedTest) async {
    return handleRepositoryCall(() async {
      final success = await remoteDataSource.updateTest(testId, updatedTest);
      if (!success) {
        throw Exception('Failed to update test');
      }
      return ApiResult.success(true);
    });
  }

  @override
  Future<ApiResult<bool>> deleteTest(String testId) async {
    return handleRepositoryCall(() async {
      final success = await remoteDataSource.deleteTest(testId);
      if (!success) {
        throw Exception('Failed to delete test');
      }
      return ApiResult.success(true);
    });
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> uploadTestImage(String testId, File imageFile) async {
    return handleRepositoryCall(() async {
      final uploadData = await remoteDataSource.uploadTestImage(testId, imageFile);
      if (uploadData == null) {
        throw Exception('Failed to upload test image');
      }
      
      return ApiResult.success({
        'url': uploadData.$1,
        'storagePath': uploadData.$2,
      });
    });
  }

  @override
  Future<ApiResult<String?>> regenerateImageUrl(TestItem test) async {
    if (test.imagePath == null || test.imagePath!.isEmpty) {
      return ApiResult.success(null);
    }

    return handleRepositoryCall(() async {
      final newUrl = await remoteDataSource.regenerateUrlFromPath(test.imagePath!);
      
      if (newUrl != null && newUrl.isNotEmpty) {
        final updatedTest = test.copyWith(imageUrl: newUrl);
        
        try {
          await remoteDataSource.updateTest(test.id, updatedTest);
        } catch (e) {
          // Log but continue
        }
      }
      
      return ApiResult.success(newUrl);
    });
  }

  @override
  Future<ApiResult<bool>> hasEditPermission(String testId, String userId) async {
    try {
      if (await adminService.isUserAdmin(userId)) {
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
}