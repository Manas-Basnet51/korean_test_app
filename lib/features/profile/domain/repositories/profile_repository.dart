import 'package:korean_language_app/features/profile/data/models/profile_model.dart';

abstract class ProfileRepository {
  Future<(bool,String)> checkAvailability();
  Future<ProfileModel> getProfile(String userId);
  Future<void> updateProfile(ProfileModel profile);
  Future<String> uploadProfileImage(String filePath);
}