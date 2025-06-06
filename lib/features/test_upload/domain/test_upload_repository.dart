import 'dart:io';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/features/tests/data/models/test_item.dart';

abstract class TestUploadRepository {
  // Test CRUD operations
  Future<ApiResult<TestItem>> createTest(TestItem test);
  Future<ApiResult<bool>> updateTest(String testId, TestItem updatedTest);
  Future<ApiResult<bool>> deleteTest(String testId);
  Future<ApiResult<Map<String, dynamic>>> uploadTestImage(String testId, File imageFile);
  Future<ApiResult<String?>> regenerateImageUrl(TestItem test);
  
  // Permission checks
  Future<ApiResult<bool>> hasEditPermission(String testId, String userId);
  Future<ApiResult<bool>> hasDeletePermission(String testId, String userId);
}