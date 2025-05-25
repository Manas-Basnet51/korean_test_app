import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/features/profile/data/models/profile_model.dart';

abstract class ProfileRepository {
  Future<ApiResult<(bool,String)>> checkAvailability();
  Future<ApiResult<ProfileModel>> getProfile(String userId);
  Future<ApiResult<void>> updateProfile(ProfileModel profile);
  Future<ApiResult<(String, String)>> uploadProfileImage(String filePath); // Changed return type
  Future<ApiResult<String?>> regenerateProfileImageUrl(String storagePath); // Added method
}