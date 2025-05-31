part of '../pages/profile_page.dart';

class ProfileContent extends StatefulWidget {
  final ProfileLoaded profileData;
  final String themeText;
  final bool isOffline;
  
  const ProfileContent({
    super.key,
    required this.profileData,
    required this.themeText,
    this.isOffline = false,
  });

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  late ProfileCubit profileCubit;
  late SnackBarCubit snackBarCubit;
  late LanguagePreferenceCubit languageCubit;
  
  @override
  void initState() {
    super.initState();
    profileCubit = context.read<ProfileCubit>();
    snackBarCubit = context.read<SnackBarCubit>();
    languageCubit = context.read<LanguagePreferenceCubit>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileHeaderWidget(
            profileData: widget.profileData, 
            onImagePickRequested: _showImagePickerOptions,
            onImageRemoved: _removeProfileImage,
            isOffline: widget.isOffline,
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                Text(
                  languageCubit.getLocalizedText(
                    korean: '한국어 학습 진행 상황',
                    english: 'Your Korean Progress',
                    hardWords: ['진행 상황'],
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                ProfileStatsWidget(
                  profileData: widget.profileData,
                  isOffline: widget.isOffline,
                ),
                
                const SizedBox(height: 24),
                
                _buildThemeSelector(isDarkMode),
                
                const SizedBox(height: 24),
                
                ProfileSettingsWidget(
                  profileData: widget.profileData,
                  onEditProfile: _showEditProfileBottomSheet,
                  onLogout: _showLogoutConfirmationBottomSheet,
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(bool isDarkMode) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          final themeCubit = context.read<ThemeCubit>();
          isDarkMode ? themeCubit.setLightTheme() : themeCubit.setDarkTheme();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                theme.brightness == Brightness.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  languageCubit.getLocalizedText(
                    korean: '앱 테마',
                    english: 'Theme: ${widget.themeText}',
                    hardWords: ['앱 테마'],
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePickerOptions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                languageCubit.getLocalizedText(
                  korean: '프로필 사진 선택',
                  english: 'Choose Profile Picture',
                  hardWords: [],
                ),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: languageCubit.getLocalizedText(
                      korean: '카메라',
                      english: 'Camera',
                      hardWords: [],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: languageCubit.getLocalizedText(
                      korean: '갤러리',
                      english: 'Gallery',
                      hardWords: [],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  if (widget.profileData.profileImageUrl.isNotEmpty)
                  _buildImageSourceOption(
                    icon: Icons.delete,
                    label: languageCubit.getLocalizedText(
                      korean: '삭제',
                      english: 'Remove',
                      hardWords: [],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfileImage();
                    },
                    color: colorScheme.error,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (color ?? colorScheme.primary).withValues( alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: color ?? colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _removeProfileImage() {
    profileCubit.removeProfileImage();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        await profileCubit.uploadImage(pickedFile.path);
      }
    } catch (e) {
      log('Error picking image: $e');
      snackBarCubit.showErrorLocalized(
        korean: '이미지 선택 오류: ${e.toString()}', 
        english: 'Error picking image: ${e.toString()}',
      );
    }
  }

  void _showEditProfileBottomSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final nameController = TextEditingController(text: widget.profileData.name);
    final emailController = TextEditingController(text: widget.profileData.email);
    final mobileController = TextEditingController(text: widget.profileData.mobileNumber ?? '');
    String selectedTopikLevel = widget.profileData.topikLevel;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          languageCubit.getLocalizedText(
                            korean: '프로필 정보 편집',
                            english: 'Edit Profile Information',
                            hardWords: [],
                          ),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildProfileField(
                      context: context,
                      icon: Icons.person,
                      label: languageCubit.getLocalizedText(
                        korean: '이름',
                        english: 'Name',
                        hardWords: [],
                      ),
                      controller: nameController,
                      color: colorScheme.primary,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildProfileField(
                      context: context,
                      icon: Icons.email,
                      label: languageCubit.getLocalizedText(
                        korean: '이메일',
                        english: 'Email',
                        hardWords: [],
                      ),
                      controller: emailController,
                      color: colorScheme.secondary,
                      readOnly: true,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildProfileField(
                      context: context,
                      icon: Icons.phone,
                      label: languageCubit.getLocalizedText(
                        korean: '휴대폰 번호',
                        english: 'Mobile Number',
                        hardWords: [],
                      ),
                      controller: mobileController,
                      color: colorScheme.tertiary,
                      keyboardType: TextInputType.phone,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      languageCubit.getLocalizedText(
                        korean: 'TOPIK 레벨',
                        english: 'TOPIK Level',
                        hardWords: [],
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Wrap(
                      spacing: 8,
                      children: ['I', 'II', 'III', 'IV', 'V', 'VI'].map((level) {
                        final isSelected = level == selectedTopikLevel;
                        return ChoiceChip(
                          label: Text(level),
                          selected: isSelected,
                          selectedColor: colorScheme.primaryContainer,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          labelStyle: TextStyle(
                            color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                selectedTopikLevel = level;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          profileCubit.updateUserProfile(
                            name: nameController.text,
                            topikLevel: selectedTopikLevel,
                            mobileNumber: mobileController.text.isEmpty ? null : mobileController.text,
                          );
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          languageCubit.getLocalizedText(
                            korean: '변경사항 저장',
                            english: 'Save Changes',
                            hardWords: [],
                          ),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }
  
  Widget _buildProfileField({
    required BuildContext context,
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required Color color,
    bool readOnly = false,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: color),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color.withValues( alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 2),
            ),
            filled: true,
            fillColor: readOnly 
                ? colorScheme.surfaceContainerHighest.withValues( alpha: 0.3)
                : colorScheme.surface,
          ),
          style: theme.textTheme.bodyLarge,
          readOnly: readOnly,
          keyboardType: keyboardType,
        ),
      ],
    );
  }

  void _showLogoutConfirmationBottomSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 6,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues( alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues( alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout,
                size: 40,
                color: colorScheme.error,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              languageCubit.getLocalizedText(
                korean: '로그아웃 확인',
                english: 'Confirm Logout',
                hardWords: [],
              ),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              languageCubit.getLocalizedText(
                korean: '정말 로그아웃 하시겠습니까?',
                english: 'Are you sure you want to logout from your account?',
                hardWords: [],
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: colorScheme.outline),
                    ),
                    child: Text(
                      languageCubit.getLocalizedText(
                        korean: '취소',
                        english: 'Cancel',
                        hardWords: [],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await context.read<AuthCubit>().signOut();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      languageCubit.getLocalizedText(
                        korean: '로그아웃',
                        english: 'Logout',
                        hardWords: [],
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}