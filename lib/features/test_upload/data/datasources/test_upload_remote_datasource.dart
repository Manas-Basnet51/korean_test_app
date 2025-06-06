import 'dart:io';
import 'package:korean_language_app/features/tests/data/models/test_item.dart';

abstract class TestUploadRemoteDataSource {
  Future<TestItem> uploadTest(TestItem test);
  Future<bool> updateTest(String testId, TestItem updatedTest);
  Future<bool> deleteTest(String testId);
  Future<(String, String)?> uploadTestImage(String testId, File imageFile);
  Future<DateTime?> getTestLastUpdated(String testId);
  Future<String?> regenerateUrlFromPath(String storagePath);
  Future<bool> verifyUrlIsWorking(String url);
}