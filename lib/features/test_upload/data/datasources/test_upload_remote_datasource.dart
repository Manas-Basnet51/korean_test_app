import 'dart:io';
import 'package:korean_language_app/core/models/test_item.dart';

abstract class TestUploadRemoteDataSource {
  /// Upload test with image atomically - test is only created if all uploads succeed
  Future<TestItem> uploadTest(TestItem test, {File? imageFile});
  
  /// Update existing test with optional new image - returns updated test
  Future<TestItem> updateTest(String testId, TestItem updatedTest, {File? imageFile});
  
  /// Delete test and all associated files
  Future<bool> deleteTest(String testId);
  
  Future<DateTime?> getTestLastUpdated(String testId);
  Future<String?> regenerateUrlFromPath(String storagePath);
  Future<bool> verifyUrlIsWorking(String url);
}