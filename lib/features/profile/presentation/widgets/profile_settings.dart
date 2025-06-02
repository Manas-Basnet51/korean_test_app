part of '../pages/profile_page.dart';

class ProfileSettingsWidget extends StatefulWidget {
  final ProfileLoaded profileData;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;

  const ProfileSettingsWidget({
    super.key,
    required this.profileData,
    required this.onEditProfile,
    required this.onLogout,
  });

  @override
  State<ProfileSettingsWidget> createState() => _ProfileSettingsWidgetState();
}

class _ProfileSettingsWidgetState extends State<ProfileSettingsWidget> {
  bool _isAdminLoading = false;
  bool _isAdmin = false;
  
  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }
  
  Future<void> _checkAdminStatus() async {
    setState(() {
      _isAdminLoading = true;
    });
    
    try {
      final userId = context.read<AuthCubit>().getCurrentUserId();
      if (userId.isNotEmpty) {
        final adminPermissionCubit = context.read<AdminPermissionCubit>();
        await adminPermissionCubit.checkAdminStatus(userId);
        
        if (adminPermissionCubit.state is AdminPermissionSuccess) {
          setState(() {
            _isAdmin = (adminPermissionCubit.state as AdminPermissionSuccess).isAdmin;
          });
        }
      }
    } catch (e) {
      // Silently handle error
    } finally {
      setState(() {
        _isAdminLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageCubit = context.watch<LanguagePreferenceCubit>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Settings heading
        Text(
          languageCubit.getLocalizedText(
            korean: '설정',
            english: 'Settings',
            hardWords: ['설정'],
          ),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // Settings buttons
        _buildSettingItem(
          context: context,
          icon: Icons.edit,
          label: languageCubit.getLocalizedText(
            korean: '프로필 편집',
            english: 'Edit Profile',
            hardWords: [],
          ),
          color: colorScheme.primary,
          onTap: widget.onEditProfile,
        ),
        
        _buildSettingItem(
          context: context,
          icon: Icons.language,
          label: languageCubit.getLocalizedText(
            korean: '언어 설정',
            english: 'Language Preferences',
            hardWords: ['언어 설정'],
          ),
          color: colorScheme.secondary,
          onTap: () => context.push(Routes.languagePreferences),
        ),
        
        // Admin section - only visible for admins or while checking
        if (_isAdminLoading || _isAdmin)...[
          _buildSettingItem(
            context: context,
            icon: Icons.admin_panel_settings,
            label: languageCubit.getLocalizedText(
              korean: '관리자 설정',
              english: 'Admin Management',
              hardWords: ['관리자 설정'],
            ),
            color: Colors.deepPurple,
            trailing: _isAdminLoading 
                ? const SizedBox(
                    width: 16, 
                    height: 16, 
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.deepPurple,
                    ),
                  )
                : null,
            onTap: _isAdminLoading 
                ? null 
                : () => context.push(Routes.adminManagement),
          ),
          const SizedBox(height: 24), 
        ],
        
        if (_isAdmin)...[
            _buildSettingItem(
              context: context,
              icon: Icons.people,
              label: languageCubit.getLocalizedText(
                korean: '사용자 관리',
                english: 'User Management',
                hardWords: ['사용자 관리'],
              ),
              color: Colors.teal,
              onTap: () => context.push(Routes.userManagement),
            ),
            const SizedBox(height: 8),
            _buildSettingItem(
              context: context,
              icon: Icons.people,
              label: languageCubit.getLocalizedText(
                korean: '',
                english: 'Migration Management',
                hardWords: [''],
              ),
              color: Colors.teal,
              onTap: () => context.push(Routes.adminMigrationPage),
            ),
            const SizedBox(height: 8),
        ],
        // Logout button
        _buildSettingItem(
          context: context,
          icon: Icons.logout,
          label: languageCubit.getLocalizedText(
            korean: '로그아웃',
            english: 'Logout',
            hardWords: [],
          ),
          color: colorScheme.error,
          onTap: widget.onLogout,
        ),
      ],
    );
  }
  
  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              trailing ?? const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}