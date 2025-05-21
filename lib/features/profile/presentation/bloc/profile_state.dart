part of 'profile_cubit.dart';

abstract class ProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

enum ProfileOperationType { uploadImage, removeImage, updateProfile }
enum ProfileOperationStatus { none ,inProgress, completed, failed }

class ProfileOperation {
  final ProfileOperationType? type;
  final ProfileOperationStatus status;
  final String? message;
  
  ProfileOperation({
    this.type,
    required this.status,
    this.message,
  });
  
  // Helper methods to check status
  bool get isInProgress => status == ProfileOperationStatus.inProgress;
  bool get isCompleted => status == ProfileOperationStatus.completed;
  bool get isFailed => status == ProfileOperationStatus.failed;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileOperation &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          status == other.status &&
          message == other.message;
          
  @override
  int get hashCode => type.hashCode ^ status.hashCode ^ (message?.hashCode ?? 0);
}

class ProfileLoaded extends ProfileState {
  final String id;
  final String name;
  final String email;
  final String profileImageUrl;
  final String topikLevel;
  final int completedTests;
  final double averageScore;
  final String? mobileNumber;
  final ProfileOperation currentOperation;

  ProfileLoaded({
    required this.id,
    required this.name,
    required this.email,
    required this.profileImageUrl,
    required this.topikLevel,
    required this.completedTests,
    required this.averageScore,
    this.mobileNumber,
    required this.currentOperation,
  });

  factory ProfileLoaded.fromModel(ProfileModel model, {required ProfileOperation operation}) {
    return ProfileLoaded(
      id: model.id,
      name: model.name,
      email: model.email,
      profileImageUrl: model.profileImageUrl,
      topikLevel: model.topikLevel,
      completedTests: model.completedTests,
      averageScore: model.averageScore,
      currentOperation: operation,
      mobileNumber: model.mobileNumber,
    );
  }
  
  // New method to create a copy with a different operation state
  ProfileLoaded copyWithOperation(ProfileOperation operation) {
    return ProfileLoaded(
      id: id,
      name: name,
      email: email,
      profileImageUrl: profileImageUrl,
      topikLevel: topikLevel,
      completedTests: completedTests,
      averageScore: averageScore,
      currentOperation: operation,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        profileImageUrl,
        topikLevel,
        completedTests,
        averageScore,
        currentOperation,
        mobileNumber
      ];
}

class ProfileError extends ProfileState {
  final String message;

  ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}