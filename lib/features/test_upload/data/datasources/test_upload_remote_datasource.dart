import 'dart:io';
import 'package:korean_language_app/core/models/test_item.dart';

abstract class TestUploadRemoteDataSource {
  /// Upload test with optional cover image and question/answer images atomically
  /// Test is only created if all uploads succeed
  Future<TestItem> uploadTest(TestItem test, {File? imageFile});
  
  /// Update existing test with optional new cover image and question/answer images
  /// Returns updated test - operation is atomic
  Future<TestItem> updateTest(String testId, TestItem updatedTest, {File? imageFile});
  
  /// Delete test and all associated files (cover image, question images, answer images)
  Future<bool> deleteTest(String testId);
  
  /// Get when the test was last updated
  Future<DateTime?> getTestLastUpdated(String testId);
  
  /// Regenerate download URL from storage path (useful for expired URLs)
  Future<String?> regenerateUrlFromPath(String storagePath);
  
  /// Verify if a URL is still working
  Future<bool> verifyUrlIsWorking(String url);
}