import 'dart:io';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/features/tests/data/models/test_item.dart';

abstract class TestUploadRepository {
  /// Create test with optional image - atomic operation
  Future<ApiResult<TestItem>> createTest(TestItem test, {File? imageFile});
  
  /// Update test with optional new image - atomic operation
  Future<ApiResult<TestItem>> updateTest(String testId, TestItem updatedTest, {File? imageFile});
  
  /// Delete test and all associated files
  Future<ApiResult<bool>> deleteTest(String testId);
  
  /// Regenerate image URL from storage path if needed
  Future<ApiResult<String?>> regenerateImageUrl(TestItem test);
  
  Future<ApiResult<bool>> hasEditPermission(String testId, String userId);
  Future<ApiResult<bool>> hasDeletePermission(String testId, String userId);
}