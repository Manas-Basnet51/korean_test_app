import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/data/base_state.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/core/services/auth_service.dart';
import 'package:korean_language_app/features/auth/domain/entities/user.dart';
import 'package:korean_language_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:korean_language_app/features/profile/data/models/profile_model.dart';
part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository profileRepository;
  final AuthService authService;
  
  bool _isStorageAvailable = true;
  ProfileLoaded? _cachedProfile;
  
  // Operation debouncing
  Timer? _operationDebounceTimer;
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  
  ProfileLoaded? get cachedProfile => _cachedProfile;
  bool get isStorageAvailable => _isStorageAvailable;

  ProfileCubit({
    required this.profileRepository,
    required this.authService,
  }) : super(ProfileInitial()) {
    _checkStorageAvailability();
    loadProfile();
  }

  Future<void> _checkStorageAvailability() async {
    final result = await profileRepository.checkAvailability();
    result.fold(
      onSuccess: (data) => _isStorageAvailable = data.$1,
      onFailure: (_, __) => _isStorageAvailable = false,
    );
  }

  UserEntity? _getCurrentUser() {
    return authService.getCurrentUser();
  }

  Future<void> loadProfile() async {
    try {
      if (_cachedProfile == null) {
        emit(const ProfileState(isLoading: true));
      }
      
      final currentUser = _getCurrentUser();
      if (currentUser == null) {
        emit(const ProfileState(error: 'User not authenticated', errorType: FailureType.auth));
        return;
      }

      final result = await profileRepository.getProfile(currentUser.uid);
      
      result.fold(
        onSuccess: (profileData) {
          final loadedProfile = ProfileLoaded.fromModel(
            profileData,
            operation: ProfileOperation(status: ProfileOperationStatus.completed)
          );
          
          _cachedProfile = loadedProfile;
          emit(loadedProfile);
        },
        onFailure: (message, type) {
          if (_cachedProfile != null) {
            emit(ProfileState(error: message, errorType: type));
            Future.delayed(const Duration(milliseconds: 100), () {
              emit(_cachedProfile!);
            });
          } else {
            emit(ProfileState(error: message, errorType: type));
          }
        },
      );
    } catch (e) {
      log('Error loading profile: ${e.toString()}');
      
      if (_cachedProfile != null) {
        emit(ProfileState(error: e.toString()));
        Future.delayed(const Duration(milliseconds: 100), () {
          emit(_cachedProfile!);
        });
      } else {
        emit(ProfileState(error: e.toString()));
      }
    }
  }

  Future<void> updateUserProfile({
    String? name,
    String? profileImageUrl,
    String? topikLevel,
    String? mobileNumber,
  }) async {
    _operationDebounceTimer?.cancel();
    
    _operationDebounceTimer = Timer(_debounceDelay, () async {
      await _performUpdateProfile(
        name: name,
        profileImageUrl: profileImageUrl,
        topikLevel: topikLevel,
        mobileNumber: mobileNumber,
      );
    });
  }

  Future<void> _performUpdateProfile({
    String? name,
    String? profileImageUrl,
    String? topikLevel,
    String? mobileNumber,
  }) async {
    try {
      final currentState = state;
      if (currentState is ProfileLoaded) {
        emit(currentState.copyWithOperation(
          ProfileOperation(
            type: ProfileOperationType.updateProfile,
            status: ProfileOperationStatus.inProgress,
          ),
        ));
        
        final updatedProfile = ProfileModel(
          id: currentState.id,
          name: name ?? currentState.name,
          email: currentState.email,
          profileImageUrl: profileImageUrl ?? currentState.profileImageUrl,
          topikLevel: topikLevel ?? currentState.topikLevel,
          completedTests: currentState.completedTests,
          averageScore: currentState.averageScore,
          mobileNumber: mobileNumber ?? currentState.mobileNumber,
        );
        
        final result = await profileRepository.updateProfile(updatedProfile);
        
        result.fold(
          onSuccess: (_) {
            final loadedProfile = ProfileLoaded.fromModel(
              updatedProfile,
              operation: ProfileOperation(
                type: ProfileOperationType.updateProfile,
                status: ProfileOperationStatus.completed,
              ),
            );
            
            _cachedProfile = loadedProfile;
            emit(loadedProfile);
            _clearOperationAfterDelay();
          },
          onFailure: (message, type) {
            emit(currentState.copyWithOperation(
              ProfileOperation(
                type: ProfileOperationType.updateProfile,
                status: ProfileOperationStatus.failed,
                message: message,
              ),
            ));
            _clearOperationAfterDelay();
          },
        );
      }
    } catch (e) {
      log('Error updating profile: ${e.toString()}');
      
      if (state is ProfileLoaded) {
        emit((state as ProfileLoaded).copyWithOperation(
          ProfileOperation(
            type: ProfileOperationType.updateProfile,
            status: ProfileOperationStatus.failed,
            message: e.toString(),
          ),
        ));
        _clearOperationAfterDelay();
      } else {
        emit(ProfileState(error: e.toString()));
      }
    }
  }

  Future<void> uploadImage(String filePath) async {
    try {
      if (!_isStorageAvailable) {
        if (state is ProfileLoaded) {
          emit((state as ProfileLoaded).copyWithOperation(
            ProfileOperation(
              type: ProfileOperationType.uploadImage,
              status: ProfileOperationStatus.failed,
              message: 'Firebase Storage is not available. Please set up a pay-as-you-go plan to enable this feature.',
            ),
          ));
          _clearOperationAfterDelay();
        }
        return;
      }
      
      final currentState = state;
      if (currentState is ProfileLoaded) {
        emit(currentState.copyWithOperation(
          ProfileOperation(
            type: ProfileOperationType.uploadImage,
            status: ProfileOperationStatus.inProgress,
          ),
        ));
        
        final imageUrlResult = await profileRepository.uploadProfileImage(filePath);
        
        imageUrlResult.fold(
          onSuccess: (uploadResult) async {
            final imageUrl = uploadResult.$1;
            final storagePath = uploadResult.$2;
            
            final updatedProfile = ProfileModel(
              id: currentState.id,
              name: currentState.name,
              email: currentState.email,
              profileImageUrl: imageUrl,
              profileImagePath: storagePath,
              topikLevel: currentState.topikLevel,
              completedTests: currentState.completedTests,
              averageScore: currentState.averageScore,
              mobileNumber: currentState.mobileNumber,
            );
            
            final updateResult = await profileRepository.updateProfile(updatedProfile);
            
            updateResult.fold(
              onSuccess: (_) {
                final loadedProfile = ProfileLoaded.fromModel(
                  updatedProfile,
                  operation: ProfileOperation(
                    type: ProfileOperationType.uploadImage,
                    status: ProfileOperationStatus.completed,
                  ),
                );
                
                _cachedProfile = loadedProfile;
                emit(loadedProfile);
                _clearOperationAfterDelay();
              },
              onFailure: (message, type) {
                emit(currentState.copyWithOperation(
                  ProfileOperation(
                    type: ProfileOperationType.uploadImage,
                    status: ProfileOperationStatus.failed,
                    message: 'Error updating profile: $message',
                  ),
                ));
                _clearOperationAfterDelay();
              },
            );
          },
          onFailure: (message, type) {
            emit(currentState.copyWithOperation(
              ProfileOperation(
                type: ProfileOperationType.uploadImage,
                status: ProfileOperationStatus.failed,
                message: 'Unable to upload image: $message',
              ),
            ));
            _clearOperationAfterDelay();
          },
        );
      }
    } catch (e) {
      log('Error in upload flow: ${e.toString()}');
      
      if (state is ProfileLoaded) {
        emit((state as ProfileLoaded).copyWithOperation(
          ProfileOperation(
            type: ProfileOperationType.uploadImage,
            status: ProfileOperationStatus.failed,
            message: e.toString(),
          ),
        ));
        _clearOperationAfterDelay();
      } else {
        emit(ProfileState(error: e.toString()));
      }
    }
  }
  
  Future<void> removeProfileImage() async {
    try {
      final currentState = state;
      if (currentState is ProfileLoaded) {
        emit(currentState.copyWithOperation(
          ProfileOperation(
            type: ProfileOperationType.removeImage,
            status: ProfileOperationStatus.inProgress,
          ),
        ));
        
        final updatedProfile = ProfileModel(
          id: currentState.id,
          name: currentState.name,
          email: currentState.email,
          profileImageUrl: '',
          profileImagePath: '',
          topikLevel: currentState.topikLevel,
          completedTests: currentState.completedTests,
          averageScore: currentState.averageScore,
          mobileNumber: currentState.mobileNumber,
        );
        
        final result = await profileRepository.updateProfile(updatedProfile);
        
        result.fold(
          onSuccess: (_) {
            final loadedProfile = ProfileLoaded.fromModel(
              updatedProfile,
              operation: ProfileOperation(
                type: ProfileOperationType.removeImage,
                status: ProfileOperationStatus.completed,
              ),
            );
            
            _cachedProfile = loadedProfile;
            emit(loadedProfile);
            _clearOperationAfterDelay();
          },
          onFailure: (message, type) {
            emit(currentState.copyWithOperation(
              ProfileOperation(
                type: ProfileOperationType.removeImage,
                status: ProfileOperationStatus.failed,
                message: message,
              ),
            ));
            _clearOperationAfterDelay();
          },
        );
      }
    } catch (e) {
      log('Error removing profile image: ${e.toString()}');
      
      if (state is ProfileLoaded) {
        emit((state as ProfileLoaded).copyWithOperation(
          ProfileOperation(
            type: ProfileOperationType.removeImage,
            status: ProfileOperationStatus.failed,
            message: e.toString(),
          ),
        ));
        _clearOperationAfterDelay();
      } else {
        emit(ProfileState(error: e.toString()));
      }
    }
  }

  Future<void> regenerateProfileImageUrl(ProfileLoaded currentProfile) async {
    try {
      if (currentProfile.profileImagePath == null || 
          currentProfile.profileImagePath!.isEmpty) {
        return;
      }

      log('Attempting to regenerate profile image URL from path: ${currentProfile.profileImagePath}');
      
      final result = await profileRepository.regenerateProfileImageUrl(
          currentProfile.profileImagePath!);
      
      result.fold(
        onSuccess: (newUrl) async {
          if (newUrl != null) {
            log('Successfully regenerated URL: $newUrl');
            
            final updatedProfile = ProfileModel(
              id: currentProfile.id,
              name: currentProfile.name,
              email: currentProfile.email,
              profileImageUrl: newUrl,
              profileImagePath: currentProfile.profileImagePath,
              topikLevel: currentProfile.topikLevel,
              completedTests: currentProfile.completedTests,
              averageScore: currentProfile.averageScore,
              mobileNumber: currentProfile.mobileNumber,
            );
            
            final updateResult = await profileRepository.updateProfile(updatedProfile);
            
            updateResult.fold(
              onSuccess: (_) {
                final loadedProfile = ProfileLoaded.fromModel(
                  updatedProfile,
                  operation: ProfileOperation(status: ProfileOperationStatus.completed),
                );
                
                _cachedProfile = loadedProfile;
                emit(loadedProfile);
                log('Profile updated with regenerated URL');
              },
              onFailure: (message, type) {
                log('Failed to update profile: $message');
                emit(ProfileState(error: message, errorType: type));
                if (_cachedProfile != null) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    emit(_cachedProfile!);
                  });
                }
              }
            );
          }
        },
        onFailure: (message, type) {
          log('Failed to regenerate URL: $message');
          emit(ProfileState(error: message, errorType: type));
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_cachedProfile != null) {
              emit(_cachedProfile!);
            }
          });
        },
      );
    } catch (e) {
      log('Error regenerating URL: ${e.toString()}');
    }
  }
  
  void _clearOperationAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (state is ProfileLoaded) {
        emit((state as ProfileLoaded).copyWithOperation(
          ProfileOperation(status: ProfileOperationStatus.none)
        ));
      }
    });
  }
  
  @override
  Future<void> close() {
    _operationDebounceTimer?.cancel();
    return super.close();
  }
}