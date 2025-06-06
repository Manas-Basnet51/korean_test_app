import 'dart:convert';
import 'dart:developer' as dev;
import 'package:korean_language_app/core/services/storage_service.dart';
import 'package:korean_language_app/features/test_results/data/datasources/test_results_local_datasources.dart';
import 'package:korean_language_app/features/test_results/data/models/test_result.dart';

class TestResultsLocalDataSourceImpl implements TestResultsLocalDataSource {
  final StorageService _storageService;
  static const String userResultsPrefix = 'USER_RESULTS_';
  static const String latestResultPrefix = 'LATEST_RESULT_';

  TestResultsLocalDataSourceImpl({required StorageService storageService})
      : _storageService = storageService;

  @override
  Future<List<TestResult>> getUserResults(String userId) async {
    try {
      final key = '$userResultsPrefix$userId';
      final jsonString = _storageService.getString(key);
      if (jsonString == null) return [];
      
      final List<dynamic> decodedJson = json.decode(jsonString);
      return decodedJson.map((item) => TestResult.fromJson(item)).toList();
    } catch (e) {
      dev.log('Error reading user results from storage: $e');
      return [];
    }
  }

  @override
  Future<void> saveUserResults(String userId, List<TestResult> results) async {
    try {
      final key = '$userResultsPrefix$userId';
      final jsonList = results.map((result) => result.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _storageService.setString(key, jsonString);
    } catch (e) {
      dev.log('Error saving user results: $e');
      throw Exception('Failed to save user results: $e');
    }
  }

  @override
  Future<TestResult?> getLatestResult(String userId, String testId) async {
    try {
      final key = '$latestResultPrefix${userId}_$testId';
      final jsonString = _storageService.getString(key);
      if (jsonString == null) return null;
      
      final Map<String, dynamic> data = json.decode(jsonString);
      return TestResult.fromJson(data);
    } catch (e) {
      dev.log('Error reading latest result from storage: $e');
      return null;
    }
  }

  @override
  Future<void> saveTestResult(TestResult result) async {
    try {
      // Save individual result
      final latestKey = '$latestResultPrefix${result.userId}_${result.testId}';
      await _storageService.setString(latestKey, json.encode(result.toJson()));
      
      // Add to user results list
      final userResults = await getUserResults(result.userId);
      
      // Remove any existing result for the same test
      final filteredResults = userResults.where((r) => r.testId != result.testId).toList();
      filteredResults.insert(0, result);
      
      // Keep only recent results (max 50)
      final limitedResults = filteredResults.take(50).toList();
      
      await saveUserResults(result.userId, limitedResults);
    } catch (e) {
      dev.log('Error saving test result: $e');
      throw Exception('Failed to save test result: $e');
    }
  }

  @override
  Future<void> clearUserResults(String userId) async {
    try {
      final userResultsKey = '$userResultsPrefix$userId';
      await _storageService.remove(userResultsKey);
      
      // Remove individual latest results for this user
      final keys = _storageService.getAllKeys();
      final keysToRemove = keys.where((key) => key.startsWith('$latestResultPrefix${userId}_'));
      
      for (final key in keysToRemove) {
        await _storageService.remove(key);
      }
    } catch (e) {
      dev.log('Error clearing user results: $e');
    }
  }

  @override
  Future<void> clearAllResults() async {
    try {
      final keys = _storageService.getAllKeys();
      final resultKeys = keys.where((key) => 
        key.startsWith(userResultsPrefix) || key.startsWith(latestResultPrefix)
      );
      
      for (final key in resultKeys) {
        await _storageService.remove(key);
      }
    } catch (e) {
      dev.log('Error clearing all results: $e');
    }
  }
}