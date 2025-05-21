part of '../pages/profile_page.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final dynamic profileData;
  final VoidCallback onImagePickRequested;
  final VoidCallback onImageRemoved;

  const ProfileHeaderWidget({
    super.key,
    required this.profileData,
    required this.onImagePickRequested,
    required this.onImageRemoved,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileCubit = context.read<ProfileCubit>();
    final isStorageAvailable = profileCubit.isStorageAvailable;
    
    // Check if there's an ongoing profile image operation
    final isUploadingImage = profileData.currentOperation?.type == ProfileOperationType.uploadImage && 
                            profileData.currentOperation?.isInProgress == true;
    
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile image section
          _buildProfileImage(
            context, 
            isUploadingImage: isUploadingImage,
            isStorageAvailable: isStorageAvailable,
          ),
          
          const SizedBox(width: 16),
          
          // User info section
          Expanded(
            child: _buildUserInfo(context),
          ),
        ],
      ),
    );
  }

  // Profile image with interactive elements
  Widget _buildProfileImage(
    BuildContext context, {
    required bool isUploadingImage,
    required bool isStorageAvailable,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final snackBarCubit = context.read<SnackBarCubit>();
    
    return GestureDetector(
      onTap: () {
        // Disable tapping while uploading
        if (isUploadingImage) return;
        
        if (isStorageAvailable) {
          onImagePickRequested();
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
            // Fixed: Only provide onBackgroundImageError when backgroundImage is not null
            CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: profileData.profileImageUrl.isNotEmpty
                  ? NetworkImage(profileData.profileImageUrl) as ImageProvider
                  : null,
              onBackgroundImageError: profileData.profileImageUrl.isNotEmpty
                  ? (_, __) {
                      // Handle image error silently
                      log('Error loading profile image');
                    }
                  : null,
              child: (profileData.profileImageUrl.isEmpty)
                  ? Text(
                      profileData.name.isNotEmpty
                          ? profileData.name[0].toUpperCase()
                          : '?',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            
            // Upload progress indicator
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
            
            // Camera or lock icon
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isStorageAvailable ? colorScheme.primary : colorScheme.outline,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUploadingImage ? Icons.hourglass_top :
                  isStorageAvailable ? Icons.camera_alt : Icons.lock,
                  color: colorScheme.onPrimary,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // User information section
  Widget _buildUserInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User name
        Text(
          profileData.name,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Email with icon
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
                profileData.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // TOPIK level badge
        _buildTopikBadge(context),
      ],
    );
  }

  // TOPIK level badge
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
              korean: 'TOPIK 레벨 ${profileData.topikLevel}',
              english: 'TOPIK Level ${profileData.topikLevel}',
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