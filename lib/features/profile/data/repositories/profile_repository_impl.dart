import 'package:firebase_auth/firebase_auth.dart';
import 'package:korean_language_app/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:korean_language_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:korean_language_app/features/profile/data/models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileDataSource dataSource;

  ProfileRepositoryImpl({required this.dataSource});

  @override
  Future<(bool,String)> checkAvailability() async {
    final data = await dataSource.checkAvailability();
    return data;
  }

  @override
  Future<ProfileModel> getProfile(String userId) async {
    final data = await dataSource.getProfile(userId);
    
    return ProfileModel(
      id: userId,
      name: data['name'] ?? 'User',
      email: data['email'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      topikLevel: data['topikLevel'] ?? 'I',
      completedTests: data['completedTests'] ?? 0,
      averageScore: data['averageScore'] ?? 0.0,
    );
  }

  @override
  Future<void> updateProfile(ProfileModel profile) async {
    await dataSource.updateProfile(profile.id, {
      'name': profile.name,
      'email': profile.email,
      'profileImageUrl': profile.profileImageUrl,
      'topikLevel': profile.topikLevel,
      'completedTests': profile.completedTests,
      'averageScore': profile.averageScore,
    });
  }

  @override
  Future<String> uploadProfileImage(String filePath) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    return await dataSource.uploadProfileImage(user.uid, filePath);
  }
}