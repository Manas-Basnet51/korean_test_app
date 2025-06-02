part of '../pages/profile_page.dart';

class ProfileHeaderWidget extends StatefulWidget {
  final ProfileLoaded profileData;
  final VoidCallback onImagePickRequested;
  final VoidCallback onImageRemoved;
  final bool isOffline;

  const ProfileHeaderWidget({
    super.key,
    required this.profileData,
    required this.onImagePickRequested,
    required this.onImageRemoved,
    this.isOffline = false,
  });

  @override
  State<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends State<ProfileHeaderWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileCubit = context.read<ProfileCubit>();
    final isStorageAvailable = profileCubit.isStorageAvailable;
    
    final isUploadingImage = widget.profileData.currentOperation.type == ProfileOperationType.uploadImage && 
                            widget.profileData.currentOperation.isInProgress == true;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues( alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          // Offline indicator for profile section
          if (widget.isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues( alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues( alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.read<LanguagePreferenceCubit>().getLocalizedText(
                        korean: '오프라인 모드 - 프로필 이미지 업로드 불가',
                        english: 'Offline Mode - Profile image upload unavailable',
                        hardWords: [],
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildProfileImageSection(
                context, 
                isUploadingImage: isUploadingImage,
                isStorageAvailable: isStorageAvailable && !widget.isOffline,
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: _buildUserInfo(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection(
    BuildContext context, {
    required bool isUploadingImage,
    required bool isStorageAvailable,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final snackBarCubit = context.read<SnackBarCubit>();
    
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (isUploadingImage) return;
            
            if (isStorageAvailable) {
              widget.onImagePickRequested();
            } else if (widget.isOffline) {
              snackBarCubit.showWarningLocalized(
                korean: '오프라인 상태에서는 프로필 이미지를 업로드할 수 없습니다.',
                english: 'Cannot upload profile image while offline.',
              );
            } else {
              snackBarCubit.showErrorLocalized(
                korean: '프로필 이미지 업로드를 사용할 수 없습니다. 파이어베이스 스토리지 설정이 필요합니다.', 
                english: 'Profile image upload is not available. Firebase Storage setup is required.',
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues( alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage: widget.profileData.profileImageUrl.isNotEmpty
                      ? NetworkImage(widget.profileData.profileImageUrl) as ImageProvider
                      : null,
                  onBackgroundImageError: widget.profileData.profileImageUrl.isNotEmpty
                      ? (exception, stackTrace) {
                          log('Error loading profile image: $exception');
                          log('Current URL: ${widget.profileData.profileImageUrl}');
                          
                          if (widget.profileData.profileImagePath != null && 
                              widget.profileData.profileImagePath!.isNotEmpty) {
                            log('Found storage path, attempting to regenerate URL from: ${widget.profileData.profileImagePath}');
                            
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted) {
                                context.read<ProfileCubit>().regenerateProfileImageUrl(widget.profileData);
                              }
                            });
                          } else {
                            log('No storage path available for regeneration');
                          }
                        }
                      : null,
                  child: (widget.profileData.profileImageUrl.isEmpty)
                      ? Text(
                          widget.profileData.name.isNotEmpty
                              ? widget.profileData.name[0].toUpperCase()
                              : '?',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
                
                if (isUploadingImage)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues( alpha: 0.3),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
                
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: widget.isOffline 
                          ? colorScheme.outline 
                          : isStorageAvailable 
                              ? colorScheme.primary 
                              : colorScheme.outline,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isOffline 
                          ? Icons.cloud_off
                          : isUploadingImage 
                              ? Icons.hourglass_top
                              : isStorageAvailable 
                                  ? Icons.camera_alt 
                                  : Icons.lock,
                      color: colorScheme.onPrimary,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Image upload status indicator
        if (widget.profileData.currentOperation.type == ProfileOperationType.uploadImage)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildImageOperationStatus(context),
          ),
      ],
    );
  }

  Widget _buildImageOperationStatus(BuildContext context) {
    final theme = Theme.of(context);
    final operation = widget.profileData.currentOperation;
    
    if (operation.status == ProfileOperationStatus.inProgress) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Uploading...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontSize: 10,
            ),
          ),
        ],
      );
    } else if (operation.status == ProfileOperationStatus.failed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 12,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            'Failed',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontSize: 10,
            ),
          ),
        ],
      );
    } else if (operation.status == ProfileOperationStatus.completed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 12,
            color: Colors.green,
          ),
          const SizedBox(width: 4),
          Text(
            'Success',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.green,
              fontSize: 10,
            ),
          ),
        ],
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildUserInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.profileData.name,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        
        const SizedBox(height: 4),
        
        Row(
          children: [
            Icon(
              Icons.email,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.profileData.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        _buildTopikBadge(context),
      ],
    );
  }

  Widget _buildTopikBadge(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageCubit = context.watch<LanguagePreferenceCubit>();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school,
            size: 14,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            languageCubit.getLocalizedText(
              korean: 'TOPIK 레벨 ${widget.profileData.topikLevel}',
              english: 'TOPIK Level ${widget.profileData.topikLevel}',
              hardWords: ['레벨'],
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}