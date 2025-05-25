part of 'profile_cubit.dart';

enum ProfileOperationType { uploadImage, removeImage, updateProfile }
enum ProfileOperationStatus { none, inProgress, completed, failed }

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

class ProfileState extends BaseState {
  const ProfileState({
    super.isLoading = false,
    super.error,
    super.errorType,
  });
  
  @override
  ProfileState copyWithBaseState({
    bool? isLoading,
    String? error,
    FailureType? errorType,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      errorType: errorType,
    );
  }
}

class ProfileInitial extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final String id;
  final String name;
  final String email;
  final String profileImageUrl;
  final String? profileImagePath; // Added field
  final String topikLevel;
  final int completedTests;
  final double averageScore;
  final String? mobileNumber;
  final ProfileOperation currentOperation;

  const ProfileLoaded({
    super.isLoading = false,
    super.error,
    super.errorType,
    required this.id,
    required this.name,
    required this.email,
    required this.profileImageUrl,
    this.profileImagePath, // Added parameter
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
      profileImagePath: model.profileImagePath, // Added
      topikLevel: model.topikLevel,
      completedTests: model.completedTests,
      averageScore: model.averageScore,
      currentOperation: operation,
      mobileNumber: model.mobileNumber,
    );
  }
  
  ProfileLoaded copyWithOperation(ProfileOperation operation) {
    return ProfileLoaded(
      id: id,
      name: name,
      email: email,
      profileImageUrl: profileImageUrl,
      profileImagePath: profileImagePath, // Added
      topikLevel: topikLevel,
      completedTests: completedTests,
      averageScore: averageScore,
      mobileNumber: mobileNumber,
      currentOperation: operation,
      isLoading: isLoading,
      error: error,
      errorType: errorType,
    );
  }
  
  @override
  ProfileLoaded copyWithBaseState({
    bool? isLoading,
    String? error,
    FailureType? errorType,
  }) {
    return ProfileLoaded(
      id: id,
      name: name,
      email: email,
      profileImageUrl: profileImageUrl,
      profileImagePath: profileImagePath, // Added
      topikLevel: topikLevel,
      completedTests: completedTests,
      averageScore: averageScore,
      mobileNumber: mobileNumber,
      currentOperation: currentOperation,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      errorType: errorType,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        id,
        name,
        email,
        profileImageUrl,
        profileImagePath, // Added
        topikLevel,
        completedTests,
        averageScore,
        currentOperation,
        mobileNumber
      ];
}