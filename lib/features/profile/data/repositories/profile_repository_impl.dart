import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:korean_language_app/core/data/base_repository.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/core/network/network_info.dart';
import 'package:korean_language_app/core/utils/exception_mapper.dart';
import 'package:korean_language_app/features/profile/data/datasources/profile_local_data_source.dart';
import 'package:korean_language_app/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:korean_language_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:korean_language_app/features/profile/data/models/profile_model.dart';

class ProfileRepositoryImpl extends BaseRepository implements ProfileRepository {
  final ProfileDataSource remoteDataSource;
  final ProfileLocalDataSource localDataSource;
  
  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(seconds: 1);

  ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required NetworkInfo networkInfo,
  }) : super(networkInfo);

  @override
  Future<ApiResult<(bool, String)>> checkAvailability() {
    return _executeWithRetry(() async {
      return await remoteDataSource.checkAvailability();
    });
  }

  @override
  Future<ApiResult<ProfileModel>> getProfile(String userId) async {
    // Check cache first if offline or cache is valid
    if (!await networkInfo.isConnected || await localDataSource.isCacheValid(userId)) {
      final cachedProfile = await localDataSource.getCachedProfile(userId);
      if (cachedProfile != null) {
        dev.log('Returning cached profile for user: $userId');
        return ApiResult.success(cachedProfile);
      }
    }

    if (!await networkInfo.isConnected) {
      return ApiResult.failure('No internet connection and no cached profile', FailureType.network);
    }

    return _executeWithRetry(() async {
      final profileData = await remoteDataSource.getProfile(userId);
      
      final profile = ProfileModel(
        id: userId,
        name: profileData['name'] ?? 'User',
        email: profileData['email'] ?? '',
        profileImageUrl: profileData['profileImageUrl'] ?? '',
        profileImagePath: profileData['profileImagePath'],
        topikLevel: profileData['topikLevel'] ?? 'I',
        completedTests: profileData['completedTests'] ?? 0,
        averageScore: (profileData['averageScore'] ?? 0.0).toDouble(),
        mobileNumber: profileData['mobileNumber'],
      );

      // Cache the profile
      try {
        await localDataSource.cacheProfile(profile);
      } catch (e) {
        dev.log('Failed to cache profile: $e');
      }

      return profile;
    });
  }

  @override
  Future<ApiResult<void>> updateProfile(ProfileModel profile) async {
    if (!await networkInfo.isConnected) {
      return ApiResult.failure('No internet connection', FailureType.network);
    }

    return _executeWithRetry(() async {
      final updateData = {
        'name': profile.name,
        'email': profile.email,
        'profileImageUrl': profile.profileImageUrl,
        'profileImagePath': profile.profileImagePath,
        'topikLevel': profile.topikLevel,
        'completedTests': profile.completedTests,
        'averageScore': profile.averageScore,
        'mobileNumber': profile.mobileNumber,
      };

      await remoteDataSource.updateProfile(profile.id, updateData);

      // Update cache
      try {
        await localDataSource.cacheProfile(profile);
      } catch (e) {
        dev.log('Failed to update cache: $e');
      }

      return;
    });
  }

  @override
  Future<ApiResult<(String, String)>> uploadProfileImage(String filePath) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return ApiResult.failure('User not authenticated', FailureType.auth);
    }

    if (!await networkInfo.isConnected) {
      return ApiResult.failure('No internet connection', FailureType.network);
    }

    return _executeWithRetry(() async {
      return await remoteDataSource.uploadProfileImage(user.uid, filePath);
    });
  }

  @override
  Future<ApiResult<String?>> regenerateProfileImageUrl(String storagePath) async {
    if (storagePath.isEmpty) {
      return ApiResult.success(null);
    }

    if (!await networkInfo.isConnected) {
      return ApiResult.failure('No internet connection', FailureType.network);
    }

    return _executeWithRetry(() async {
      return await remoteDataSource.regenerateUrlFromPath(storagePath);
    });
  }

  Future<ApiResult<T>> _executeWithRetry<T>(Future<T> Function() operation) async {
    Exception? lastException;
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final result = await operation();
        return ApiResult.success(result);
      } catch (e) {
        lastException = e as Exception;
        
        if (attempt == _maxRetries) {
          break;
        }
        
        // Exponential backoff
        final delay = Duration(seconds: _initialRetryDelay.inSeconds * attempt);
        await Future.delayed(delay);
        
        dev.log('Retry attempt $attempt failed: $e. Retrying in ${delay.inSeconds}s...');
      }
    }
    
    return ExceptionMapper.mapExceptionToApiResult(lastException!);
  }
}