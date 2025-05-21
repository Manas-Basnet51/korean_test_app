import 'package:firebase_auth/firebase_auth.dart';
import 'package:korean_language_app/core/data/base_repository.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/core/network/network_info.dart';
import 'package:korean_language_app/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:korean_language_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:korean_language_app/features/profile/data/models/profile_model.dart';

class ProfileRepositoryImpl extends BaseRepository implements ProfileRepository {
  final ProfileDataSource dataSource;

  ProfileRepositoryImpl({
    required this.dataSource,
    required NetworkInfo networkInfo,
  }) : super(networkInfo);

  @override
  Future<ApiResult<(bool,String)>> checkAvailability() {
    return handleRepositoryCall(() => dataSource.checkAvailability());
  }

  @override
  Future<ApiResult<ProfileModel>> getProfile(String userId) {
    return handleRepositoryCall(() async {
      final result = await dataSource.getProfile(userId);
      
      return result.fold(
        onSuccess: (data) {
          final profile = ProfileModel(
            id: userId,
            name: data['name'] ?? 'User',
            email: data['email'] ?? '',
            profileImageUrl: data['profileImageUrl'] ?? '',
            topikLevel: data['topikLevel'] ?? 'I',
            completedTests: data['completedTests'] ?? 0,
            averageScore: data['averageScore'] ?? 0.0,
            mobileNumber: data['mobileNumber'],
          );
          return ApiResult.success(profile);
        },
        onFailure: (message, type) => ApiResult.failure(message, type),
      );
    });
  }

  @override
  Future<ApiResult<void>> updateProfile(ProfileModel profile) {
    return handleRepositoryCall(() async {
      final result = await dataSource.updateProfile(profile.id, {
        'name': profile.name,
        'email': profile.email,
        'profileImageUrl': profile.profileImageUrl,
        'topikLevel': profile.topikLevel,
        'completedTests': profile.completedTests,
        'averageScore': profile.averageScore,
        'mobileNumber': profile.mobileNumber,
      });
      
      return result;
    });
  }

  @override
  Future<ApiResult<String>> uploadProfileImage(String filePath) {
    return handleRepositoryCall(() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return ApiResult.failure('User not authenticated', FailureType.auth);
      }
      
      final result = await dataSource.uploadProfileImage(user.uid, filePath);
      return result;
    });
  }
}