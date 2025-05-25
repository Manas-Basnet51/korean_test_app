import 'package:equatable/equatable.dart';

class ProfileModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String profileImageUrl;
  final String? profileImagePath;
  final String topikLevel;
  final int completedTests;
  final double averageScore;
  final String? mobileNumber;

  const ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl = '',
    this.profileImagePath,
    this.topikLevel = 'I',
    this.completedTests = 0,
    this.averageScore = 0.0,
    this.mobileNumber, 
  });

  ProfileModel copyWith({
    String? name,
    String? email,
    String? profileImageUrl,
    String? profileImagePath,
    String? topikLevel,
    int? completedTests,
    double? averageScore,
    String? mobileNumber,
  }) {
    return ProfileModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      topikLevel: topikLevel ?? this.topikLevel,
      completedTests: completedTests ?? this.completedTests,
      averageScore: averageScore ?? this.averageScore,
      mobileNumber: mobileNumber ?? this.mobileNumber,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        profileImageUrl,
        profileImagePath, // Added to props
        topikLevel,
        completedTests,
        averageScore,
        mobileNumber
      ];
}