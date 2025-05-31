import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/core/presentation/widgets/errors/error_widget.dart';
import 'package:korean_language_app/core/routes/app_router.dart';
import 'package:korean_language_app/features/admin/presentation/bloc/admin_permission_cubit.dart';
import 'package:korean_language_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:korean_language_app/core/presentation/connectivity/bloc/connectivity_cubit.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';
import 'package:korean_language_app/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:korean_language_app/core/presentation/snackbar/bloc/snackbar_cubit.dart';
import 'package:korean_language_app/core/presentation/theme/bloc/theme_cubit.dart';
import 'package:korean_language_app/core/presentation/widgets/errors/error_boundary_widget.dart';

part '../widgets/profile_content.dart';
part '../widgets/profile_header.dart';
part '../widgets/profile_stats.dart';
part '../widgets/profile_settings.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ConnectivityCubit _connectivityCubit;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _connectivityCubit = context.read<ConnectivityCubit>();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectivityCubit.checkConnectivity();
      setState(() {
        _isInitialized = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final snackBarCubit = context.read<SnackBarCubit>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final languageCubit = context.watch<LanguagePreferenceCubit>();
    final themeText = isDarkMode 
        ? languageCubit.getLocalizedText(
            korean: '다크 모드',
            english: 'Dark Mode',
            hardWords: ['다크 모드'],
          )
        : languageCubit.getLocalizedText(
            korean: '라이트 모드',
            english: 'Light Mode',
            hardWords: ['라이트 모드'],
          );
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageCubit.getLocalizedText(
            korean: '내 프로필',
            english: 'My Profile',
            hardWords: [],
          ),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        actions: [
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return IconButton(
                icon: Icon(
                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: colorScheme.primary,
                ),
                tooltip: isDarkMode 
                  ? languageCubit.getLocalizedText(
                      korean: '라이트 모드로 전환',
                      english: 'Switch to Light Mode',
                      hardWords: ['전환'],
                    )
                  : languageCubit.getLocalizedText(
                      korean: '다크 모드로 전환',
                      english: 'Switch to Dark Mode',
                      hardWords: ['전환'],
                    ),
                onPressed: () {
                  final themeCubit = context.read<ThemeCubit>();
                  isDarkMode ? themeCubit.setLightTheme() : themeCubit.setDarkTheme();
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, connectivityState) {
          final bool isOffline = connectivityState is ConnectivityDisconnected;
          
          return Column(
            children: [
              // Connectivity status banner
              if (isOffline)
                ErrorView(
                  message: '',
                  errorType: FailureType.network,
                  onRetry: () {
                    context.read<ConnectivityCubit>().checkConnectivity();
                  },
                  isCompact: true,
                ),
                
              Expanded(
                child: BlocConsumer<ProfileCubit, ProfileState>(
                  listener: (context, state) {
                    if (state.hasError) {
                      snackBarCubit.showErrorLocalized(
                        korean: state.error ?? '오류가 발생했습니다.',
                        english: state.error ?? 'An error occurred.',
                      );
                    }
                    
                    if (state is ProfileLoaded) {
                      final operation = state.currentOperation;
                      
                      if (operation.status == ProfileOperationStatus.inProgress) {
                        String message = _getOperationProgressMessage(operation.type, languageCubit);
                        snackBarCubit.showProgressLocalized(
                          korean: message,
                          english: message,
                        );
                      } else if (operation.status == ProfileOperationStatus.completed) {
                        String message = _getOperationSuccessMessage(operation.type, languageCubit);
                        snackBarCubit.showSuccessLocalized(
                          korean: message,
                          english: message,
                        );
                      } else if (operation.status == ProfileOperationStatus.failed) {
                        String message = operation.message ?? 
                          languageCubit.getLocalizedText(
                            korean: '작업 실패. 다시 시도해주세요.',
                            english: 'Operation failed. Please try again.',
                          );
                        snackBarCubit.showErrorLocalized(
                          korean: message,
                          english: message,
                        );
                      }
                    }
                  },
                  builder: (context, state) {
                    if (!_isInitialized || state is ProfileInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    // If offline and loading with no cached data, show default profile with offline indicators
                    if (isOffline && state.isLoading && context.read<ProfileCubit>().cachedProfile == null) {
                      return _buildOfflineProfileView(context);
                    }
                    
                    // If loading and no cached data
                    if (state.isLoading && context.read<ProfileCubit>().cachedProfile == null) {
                      return Center(
                        child: CircularProgressIndicator(color: colorScheme.primary),
                      );
                    } 
                    
                    // If profile loaded successfully
                    else if (state is ProfileLoaded) {
                      return ProfileContent(
                        profileData: state,
                        themeText: themeText,
                        isOffline: isOffline,
                      );
                    } 
                    
                    // If error but cached data available
                    else if (state.hasError && context.read<ProfileCubit>().cachedProfile != null) {
                      return Column(
                        children: [
                          ErrorView(
                            message: state.error ?? '',
                            errorType: state.errorType,
                            onRetry: () {
                              context.read<ProfileCubit>().loadProfile();
                            },
                            isCompact: true,
                          ),
                          Expanded(
                            child: ProfileContent(
                              profileData: context.read<ProfileCubit>().cachedProfile!,
                              themeText: themeText,
                              isOffline: isOffline,
                            ),
                          ),
                        ],
                      );
                    } 
                    
                    // If error and no cached data
                    else if (state.hasError) {
                      log('Error: ${state.error}, Type: ${state.errorType}');
                      return ErrorView(
                        message: state.error ?? '',
                        errorType: state.errorType,
                        onRetry: () {
                          context.read<ProfileCubit>().loadProfile();
                        },
                      );
                    } 
                    
                    // Default case
                    else {
                      return Center(
                        child: Text(
                          languageCubit.getLocalizedText(
                            korean: '프로필을 보려면 로그인하세요',
                            english: 'Please log in to view your profile',
                            hardWords: ['로그인하세요'],
                          ),
                          style: theme.textTheme.bodyLarge,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  String _getOperationProgressMessage(ProfileOperationType? type, LanguagePreferenceCubit languageCubit) {
    switch (type) {
      case ProfileOperationType.updateProfile:
        return languageCubit.getLocalizedText(
          korean: '프로필 업데이트 중...',
          english: 'Updating profile...',
        );
      case ProfileOperationType.uploadImage:
        return languageCubit.getLocalizedText(
          korean: '프로필 이미지 업로드 중...',
          english: 'Uploading profile image...',
        );
      case ProfileOperationType.removeImage:
        return languageCubit.getLocalizedText(
          korean: '프로필 이미지 제거 중...',
          english: 'Removing profile image...',
        );
      default:
        return languageCubit.getLocalizedText(
          korean: '작업 처리 중...',
          english: 'Processing...',
        );
    }
  }
  
  Widget _buildOfflineProfileView(BuildContext context) {
    final theme = Theme.of(context);
    final languageCubit = context.watch<LanguagePreferenceCubit>();
    final currentUser = context.read<AuthCubit>().state;
    
    // Create a basic offline profile using current user data
    String userName = 'User';
    String userEmail = '';
    
    if (currentUser is Authenticated) {
      userName = currentUser.user.displayName ?? 'User';
      userEmail = currentUser.user.email ?? '';
    }
    
    final offlineProfile = ProfileLoaded(
      id: 'offline',
      name: userName,
      email: userEmail,
      profileImageUrl: '',
      topikLevel: 'I',
      completedTests: 0,
      averageScore: 0.0,
      currentOperation: ProfileOperation(status: ProfileOperationStatus.none),
    );
    
    return ProfileContent(
      profileData: offlineProfile,
      themeText: theme.brightness == Brightness.dark 
          ? languageCubit.getLocalizedText(korean: '다크 모드', english: 'Dark Mode', hardWords: ['다크 모드'])
          : languageCubit.getLocalizedText(korean: '라이트 모드', english: 'Light Mode', hardWords: ['라이트 모드']),
      isOffline: true,
    );
  }
  
  String _getOperationSuccessMessage(ProfileOperationType? type, LanguagePreferenceCubit languageCubit) {
    switch (type) {
      case ProfileOperationType.updateProfile:
        return languageCubit.getLocalizedText(
          korean: '프로필이 성공적으로 업데이트되었습니다',
          english: 'Profile updated successfully',
        );
      case ProfileOperationType.uploadImage:
        return languageCubit.getLocalizedText(
          korean: '프로필 이미지가 성공적으로 업로드되었습니다',
          english: 'Profile image uploaded successfully',
        );
      case ProfileOperationType.removeImage:
        return languageCubit.getLocalizedText(
          korean: '프로필 이미지가 성공적으로 제거되었습니다',
          english: 'Profile image removed successfully',
        );
      default:
        return languageCubit.getLocalizedText(
          korean: '작업이 완료되었습니다',
          english: 'Operation completed successfully',
        );
    }
  }
}