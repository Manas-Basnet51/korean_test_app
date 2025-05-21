import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:korean_language_app/features/profile/data/models/profile_model.dart';
part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository profileRepository;
  final FirebaseAuth auth;
  
  // Flag to track if Firebase Storage is available
  bool _isStorageAvailable = true;
  
  // Cache for profile data
  ProfileLoaded? _cachedProfile;
  
  // Getter for cached profile
  ProfileLoaded? get cachedProfile => _cachedProfile;

  ProfileCubit({
    required this.profileRepository,
    required this.auth,
  }) : super(ProfileInitial()) {
    _checkStorageAvailability();
    loadProfile();
  }

  // Method to check if Firebase Storage is available
  Future<void> _checkStorageAvailability() async {
    await profileRepository.checkAvailability().then((value) => _isStorageAvailable = value.$1);
  }

  // Getter to check if storage is available
  bool get isStorageAvailable => _isStorageAvailable;

  Future<void> loadProfile() async {
    try {
      // Only show loading state if we don't have cached data
      if (_cachedProfile == null) {
        emit(ProfileLoading());
      }
      
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        emit(ProfileError('User not authenticated'));
        return;
      }

      final profileData = await profileRepository.getProfile(currentUser.uid);
      
      final loadedProfile = ProfileLoaded.fromModel(
        profileData,
        operation: ProfileOperation(status: ProfileOperationStatus.completed)
      );
      
      // Update cache
      _cachedProfile = loadedProfile;
      
      emit(loadedProfile); 
    } catch (e) {
      log('Error loading profile: ${e.toString()}');
      
      // If we have cached data, keep showing it but emit error notification via listener
      if (_cachedProfile != null) {
        emit(ProfileError(e.toString()));
        Future.delayed(const Duration(milliseconds: 100), () {
          emit(_cachedProfile!);
        });
      } else {
        emit(ProfileError(e.toString()));
      }
    }
  }

  Future<void> updateUserProfile({
    String? name,
    String? profileImageUrl,
    String? topikLevel,
    String? mobileNumber,
  }) async {
    try {
      final currentState = state;
      if (currentState is ProfileLoaded) {
        // Mark operation as in progress but keep showing the profile
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
        
        await profileRepository.updateProfile(updatedProfile);
        
        final loadedProfile = ProfileLoaded.fromModel(
          updatedProfile,
          operation: ProfileOperation(
            type: ProfileOperationType.updateProfile,
            status: ProfileOperationStatus.completed,
          ),
        );
        
        // Update cache
        _cachedProfile = loadedProfile;
        
        // Mark operation as completed and update profile data
        emit(loadedProfile);
        
        // Clear operation status after a delay
        _clearOperationAfterDelay();
      }
    } catch (e) {
      log('Error updating profile: ${e.toString()}');
      
      if (state is ProfileLoaded) {
        // Mark operation as failed but keep showing the profile
        emit((state as ProfileLoaded).copyWithOperation(
          ProfileOperation(
            type: ProfileOperationType.updateProfile,
            status: ProfileOperationStatus.failed,
            message: e.toString(),
          ),
        ));
        
        // Clear operation status after a delay
        _clearOperationAfterDelay();
      } else {
        emit(ProfileError(e.toString()));
      }
    }
  }

  Future<void> uploadImage(String filePath) async {
    try {
      // Check if storage is available
      if (!_isStorageAvailable) {
        if (state is ProfileLoaded) {
          // Show storage unavailable message but keep profile visible
          emit((state as ProfileLoaded).copyWithOperation(
            ProfileOperation(
              type: ProfileOperationType.uploadImage,
              status: ProfileOperationStatus.failed,
              message: 'Firebase Storage is not available. Please set up a pay-as-you-go plan to enable this feature.',
            ),
          ));
          
          // Clear operation status after a delay
          _clearOperationAfterDelay();
        }
        return;
      }
      
      final currentState = state;
      if (currentState is ProfileLoaded) {
        // Mark upload operation as in progress but keep showing the profile
        emit(currentState.copyWithOperation(
          ProfileOperation(
            type: ProfileOperationType.uploadImage,
            status: ProfileOperationStatus.inProgress,
          ),
        ));
        
        try {
          final imageUrl = await profileRepository.uploadProfileImage(filePath);
          
          final updatedProfile = ProfileModel(
            id: currentState.id,
            name: currentState.name,
            email: currentState.email,
            profileImageUrl: imageUrl,
            topikLevel: currentState.topikLevel,
            completedTests: currentState.completedTests,
            averageScore: currentState.averageScore,
            mobileNumber: currentState.mobileNumber,
          );
          
          await profileRepository.updateProfile(updatedProfile);
          
          final loadedProfile = ProfileLoaded.fromModel(
            updatedProfile,
            operation: ProfileOperation(
              type: ProfileOperationType.uploadImage,
              status: ProfileOperationStatus.completed,
            ),
          );
          
          // Update cache
          _cachedProfile = loadedProfile;
          
          // Mark upload as completed and update profile data
          emit(loadedProfile);
          
          // Clear operation status after a delay
          _clearOperationAfterDelay();
        } catch (storageError) {
          log('Storage error: ${storageError.toString()}');
          
          // Mark upload as failed but keep showing the profile
          emit(currentState.copyWithOperation(
            ProfileOperation(
              type: ProfileOperationType.uploadImage,
              status: ProfileOperationStatus.failed,
              message: 'Unable to upload image: ${storageError.toString()}',
            ),
          ));
          
          // Clear operation status after a delay
          _clearOperationAfterDelay();
        }
      }
    } catch (e) {
      log('Error in upload flow: ${e.toString()}');
      
      if (state is ProfileLoaded) {
        // Mark upload as failed but keep showing the profile
        emit((state as ProfileLoaded).copyWithOperation(
          ProfileOperation(
            type: ProfileOperationType.uploadImage,
            status: ProfileOperationStatus.failed,
            message: e.toString(),
          ),
        ));
        
        // Clear operation status after a delay
        _clearOperationAfterDelay();
      } else {
        emit(ProfileError(e.toString()));
      }
    }
  }
  
  Future<void> removeProfileImage() async {
    try {
      final currentState = state;
      if (currentState is ProfileLoaded) {
        // Mark removal operation as in progress but keep showing the profile
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
          profileImageUrl: '', // Clear the profile image URL
          topikLevel: currentState.topikLevel,
          completedTests: currentState.completedTests,
          averageScore: currentState.averageScore,
          mobileNumber: currentState.mobileNumber,
        );
        
        await profileRepository.updateProfile(updatedProfile);
        
        final loadedProfile = ProfileLoaded.fromModel(
          updatedProfile,
          operation: ProfileOperation(
            type: ProfileOperationType.removeImage,
            status: ProfileOperationStatus.completed,
          ),
        );
        
        // Update cache
        _cachedProfile = loadedProfile;
        
        // Mark removal as completed and update profile data
        emit(loadedProfile);
        
        // Clear operation status after a delay
        _clearOperationAfterDelay();
      }
    } catch (e) {
      log('Error removing profile image: ${e.toString()}');
      
      if (state is ProfileLoaded) {
        // Mark removal as failed but keep showing the profile
        emit((state as ProfileLoaded).copyWithOperation(
          ProfileOperation(
            type: ProfileOperationType.removeImage,
            status: ProfileOperationStatus.failed,
            message: e.toString(),
          ),
        ));
        
        // Clear operation status after a delay
        _clearOperationAfterDelay();
      } else {
        emit(ProfileError(e.toString()));
      }
    }
  }
  
  // Helper method to clear operation status after a delay
  void _clearOperationAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (state is ProfileLoaded) {
        emit((state as ProfileLoaded).copyWithOperation(ProfileOperation(status: ProfileOperationStatus.none)));
      }
    });
  }
}