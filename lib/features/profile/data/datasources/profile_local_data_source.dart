import 'dart:convert';
import 'dart:developer' as dev;
import 'package:korean_language_app/features/profile/data/models/profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ProfileLocalDataSource {
  Future<ProfileModel?> getCachedProfile(String userId);
  Future<void> cacheProfile(ProfileModel profile);
  Future<void> clearCachedProfile(String userId);
  Future<bool> hasCachedProfile(String userId);
  Future<bool> isCacheValid(String userId);
  Future<void> invalidateCache(String userId);
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _profilePrefix = 'CACHED_PROFILE_';
  static const String _timestampPrefix = 'PROFILE_CACHE_TIME_';
  static const Duration _cacheValidityDuration = Duration(hours: 24);

  ProfileLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<ProfileModel?> getCachedProfile(String userId) async {
    try {
      final cacheKey = '$_profilePrefix$userId';
      final jsonString = sharedPreferences.getString(cacheKey);
      
      if (jsonString == null) return null;
      
      final Map<String, dynamic> profileData = json.decode(jsonString);
      final profile = ProfileModel(
        id: profileData['id'] ?? userId,
        name: profileData['name'] ?? 'User',
        email: profileData['email'] ?? '',
        profileImageUrl: profileData['profileImageUrl'] ?? '',
        profileImagePath: profileData['profileImagePath'],
        topikLevel: profileData['topikLevel'] ?? 'I',
        completedTests: profileData['completedTests'] ?? 0,
        averageScore: (profileData['averageScore'] ?? 0.0).toDouble(),
        mobileNumber: profileData['mobileNumber'],
      );
      
      dev.log('Retrieved cached profile for user: $userId');
      return profile;
    } catch (e) {
      dev.log('Error reading cached profile: $e');
      await clearCachedProfile(userId);
      return null;
    }
  }

  @override
  Future<void> cacheProfile(ProfileModel profile) async {
    try {
      final cacheKey = '$_profilePrefix${profile.id}';
      final timestampKey = '$_timestampPrefix${profile.id}';
      
      final profileData = {
        'id': profile.id,
        'name': profile.name,
        'email': profile.email,
        'profileImageUrl': profile.profileImageUrl,
        'profileImagePath': profile.profileImagePath,
        'topikLevel': profile.topikLevel,
        'completedTests': profile.completedTests,
        'averageScore': profile.averageScore,
        'mobileNumber': profile.mobileNumber,
      };
      
      final jsonString = json.encode(profileData);
      await sharedPreferences.setString(cacheKey, jsonString);
      await sharedPreferences.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
      
      dev.log('Cached profile for user: ${profile.id}');
    } catch (e) {
      dev.log('Error caching profile: $e');
      throw Exception('Failed to cache profile: $e');
    }
  }

  @override
  Future<void> clearCachedProfile(String userId) async {
    try {
      final cacheKey = '$_profilePrefix$userId';
      final timestampKey = '$_timestampPrefix$userId';
      
      await sharedPreferences.remove(cacheKey);
      await sharedPreferences.remove(timestampKey);
      
      dev.log('Cleared cached profile for user: $userId');
    } catch (e) {
      dev.log('Error clearing cached profile: $e');
    }
  }

  @override
  Future<bool> hasCachedProfile(String userId) async {
    try {
      final cacheKey = '$_profilePrefix$userId';
      return sharedPreferences.containsKey(cacheKey);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isCacheValid(String userId) async {
    try {
      final timestampKey = '$_timestampPrefix$userId';
      final timestamp = sharedPreferences.getInt(timestampKey);
      
      if (timestamp == null) return false;
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final cacheAge = DateTime.now().difference(cacheTime);
      
      return cacheAge < _cacheValidityDuration;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> invalidateCache(String userId) async {
    final timestampKey = '$_timestampPrefix$userId';
    await sharedPreferences.remove(timestampKey);
    dev.log('Invalidated cache for user: $userId');
  }
}