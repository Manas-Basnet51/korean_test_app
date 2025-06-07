import 'dart:io';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/core/models/test_item.dart';

abstract class TestUploadRepository {
  /// Create test with optional cover image - atomic operation
  /// Handles upload of cover image, question images, and answer images
  Future<ApiResult<TestItem>> createTest(TestItem test, {File? imageFile});
  
  /// Update test with optional new cover image - atomic operation
  /// Handles upload of new images and cleanup of old ones
  Future<ApiResult<TestItem>> updateTest(String testId, TestItem updatedTest, {File? imageFile});
  
  /// Delete test and all associated files (cover, question, and answer images)
  Future<ApiResult<bool>> deleteTest(String testId);
  
  /// Regenerate cover image URL from storage path if needed
  Future<ApiResult<String?>> regenerateImageUrl(TestItem test);
  
  /// Regenerate all image URLs (cover, question images, answer images) for a test
  /// Returns updated test if any URLs were regenerated, null if no updates needed
  Future<ApiResult<TestItem?>> regenerateAllImageUrls(TestItem test);
  
  /// Verify if all image URLs in a test are working
  Future<ApiResult<bool>> verifyImageUrls(TestItem test);
  
  /// Check if user has permission to edit the test
  Future<ApiResult<bool>> hasEditPermission(String testId, String userId);
  
  /// Check if user has permission to delete the test
  Future<ApiResult<bool>> hasDeletePermission(String testId, String userId);
}