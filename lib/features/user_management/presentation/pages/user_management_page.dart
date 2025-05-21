import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/utils/admin_guard.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';
import 'package:korean_language_app/features/user_management/presentation/bloc/user_management_cubit.dart';
import 'package:korean_language_app/features/user_management/data/models/user_management_model.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> with AdminAccessMixin {
  final TextEditingController _searchController = TextEditingController();
  List<UserManagementModel> _filteredUsers = [];

  late UserManagementCubit _userManagementCubit;
  late LanguagePreferenceCubit languageCubit;
  
  @override
  void initState() {
    _userManagementCubit = context.read<UserManagementCubit>();
    languageCubit = context.read<LanguagePreferenceCubit>();
    super.initState();
    _loadUsers();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _loadUsers() {
    _userManagementCubit.loadUsers();
  }
  
  void _filterUsers(List<UserManagementModel> users, String query) {
    if (query.isEmpty) {
      setState(() => _filteredUsers = users);
      return;
    }
    
    final lowercaseQuery = query.toLowerCase();
    final filtered = users.where((user) {
      return user.name.toLowerCase().contains(lowercaseQuery) ||
             user.email.toLowerCase().contains(lowercaseQuery) ||
             user.id.toLowerCase().contains(lowercaseQuery);
    }).toList();
    
    setState(() => _filteredUsers = filtered);
  }
  
  Future<void> _toggleUserStatus(UserManagementModel user) async {
    // Show confirmation dialog
    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          languageCubit.getLocalizedText(
            korean: user.isActive ? '사용자 비활성화' : '사용자 활성화',
            english: user.isActive ? 'Deactivate User' : 'Activate User',
          ),
        ),
        content: Text(
          languageCubit.getLocalizedText(
            korean: user.isActive 
                ? '${user.email}를 비활성화하시겠습니까?' 
                : '${user.email}를 활성화하시겠습니까?',
            english: user.isActive 
                ? 'Are you sure you want to deactivate ${user.email}?' 
                : 'Are you sure you want to activate ${user.email}?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              languageCubit.getLocalizedText(
                korean: '취소',
                english: 'Cancel',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: user.isActive 
                  ? Theme.of(context).colorScheme.error 
                  : Colors.green,
            ),
            child: Text(
              languageCubit.getLocalizedText(
                korean: user.isActive ? '비활성화' : '활성화',
                english: user.isActive ? 'Deactivate' : 'Activate',
              ),
            ),
          ),
        ],
      ),
    );
    
    if (shouldUpdate == true) {
      await _userManagementCubit.updateUserStatus(user.id, user.isActive);
    }
  }
  
  Future<void> _deleteUser(UserManagementModel user) async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          languageCubit.getLocalizedText(
            korean: '사용자 삭제',
            english: 'Delete User',
          ),
        ),
        content: Text(
          languageCubit.getLocalizedText(
            korean: '${user.email}를 영구적으로 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.',
            english: 'Are you sure you want to permanently delete ${user.email}? This action cannot be undone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              languageCubit.getLocalizedText(
                korean: '취소',
                english: 'Cancel',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              languageCubit.getLocalizedText(
                korean: '삭제',
                english: 'Delete',
              ),
            ),
          ),
        ],
      ),
    );
    
    if (shouldDelete == true) {
      await _userManagementCubit.deleteUser(user.id);
    }
  }
  
  Future<void> _resetPassword(UserManagementModel user) async {
    // Show confirmation dialog
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          languageCubit.getLocalizedText(
            korean: '비밀번호 재설정',
            english: 'Reset Password',
          ),
        ),
        content: Text(
          languageCubit.getLocalizedText(
            korean: '${user.email}의 비밀번호 재설정 이메일을 보내시겠습니까?',
            english: 'Are you sure you want to send a password reset email to ${user.email}?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              languageCubit.getLocalizedText(
                korean: '취소',
                english: 'Cancel',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              languageCubit.getLocalizedText(
                korean: '재설정 이메일 보내기',
                english: 'Send Reset Email',
              ),
            ),
          ),
        ],
      ),
    );
    
    if (shouldReset == true) {
      await _userManagementCubit.resetUserPassword(user.email);
    }
  }
  
  void _showUserDetails(UserManagementModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  
                  // User header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues( alpha: 0.3),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        // User avatar
                        Hero(
                          tag: 'user-avatar-${user.id}',
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: user.isAdmin
                                ? colorScheme.secondaryContainer
                                : user.isActive
                                    ? colorScheme.primaryContainer
                                    : colorScheme.surfaceContainerHighest,
                            backgroundImage: user.photoUrl != null 
                                ? NetworkImage(user.photoUrl!) 
                                : null,
                            child: user.photoUrl == null
                                ? Icon(
                                    user.isAdmin
                                        ? Icons.admin_panel_settings
                                        : Icons.person,
                                    color: user.isAdmin
                                        ? colorScheme.onSecondaryContainer
                                        : user.isActive
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurfaceVariant,
                                    size: 40,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 20),
                        
                        // User name and email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name != 'Unknown' ? user.name : user.id,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email != 'Unknown' ? user.email : 'Email unknown',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // User details
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section title
                        Text(
                          languageCubit.getLocalizedText(
                            korean: '사용자 세부 정보',
                            english: 'User Details',
                          ),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // ID
                        _buildInfoItem(
                          icon: Icons.fingerprint,
                          title: languageCubit.getLocalizedText(
                            korean: '사용자 ID',
                            english: 'User ID',
                          ),
                          value: user.id,
                          color: colorScheme.primary,
                          theme: theme,
                        ),
                        
                        const Divider(height: 32),
                        
                        // Status
                        _buildInfoItem(
                          icon: user.isActive ? Icons.check_circle : Icons.cancel,
                          title: languageCubit.getLocalizedText(
                            korean: '상태',
                            english: 'Status',
                          ),
                          value: user.isActive
                              ? languageCubit.getLocalizedText(
                                  korean: '활성',
                                  english: 'Active',
                                )
                              : languageCubit.getLocalizedText(
                                  korean: '비활성',
                                  english: 'Inactive',
                                ),
                          color: user.isActive ? Colors.green : Colors.red,
                          theme: theme,
                        ),
                        
                        const Divider(height: 32),
                        
                        // Role
                        _buildInfoItem(
                          icon: Icons.admin_panel_settings,
                          title: languageCubit.getLocalizedText(
                            korean: '역할',
                            english: 'Role',
                          ),
                          value: user.isAdmin
                              ? languageCubit.getLocalizedText(
                                  korean: '관리자',
                                  english: 'Admin',
                                )
                              : languageCubit.getLocalizedText(
                                  korean: '일반 사용자',
                                  english: 'Regular User',
                                ),
                          color: user.isAdmin ? colorScheme.secondary : colorScheme.primary,
                          theme: theme,
                        ),
                        
                        const Divider(height: 32),
                        
                        // Created date
                        _buildInfoItem(
                          icon: Icons.calendar_today,
                          title: languageCubit.getLocalizedText(
                            korean: '생성일',
                            english: 'Created On',
                          ),
                          value: _formatDate(user.createdAt),
                          color: colorScheme.primary,
                          theme: theme,
                        ),
                        
                        if (user.lastLoginAt.isNotEmpty) ...[
                          const Divider(height: 32),
                          
                          // Last login
                          _buildInfoItem(
                            icon: Icons.login,
                            title: languageCubit.getLocalizedText(
                              korean: '마지막 로그인',
                              english: 'Last Login',
                            ),
                            value: _formatDate(user.lastLoginAt),
                            color: colorScheme.primary,
                            theme: theme,
                          ),
                        ],
                        
                        const SizedBox(height: 32),
                        
                        // Actions section
                        Text(
                          languageCubit.getLocalizedText(
                            korean: '사용자 관리',
                            english: 'User Management',
                          ),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Reset password button
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.lock_reset),
                                label: Text(
                                  languageCubit.getLocalizedText(
                                    korean: '비밀번호 재설정',
                                    english: 'Reset Password',
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primaryContainer,
                                  foregroundColor: colorScheme.onPrimaryContainer,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _resetPassword(user);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Toggle status button
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: Icon(
                                  user.isActive ? Icons.block : Icons.check_circle,
                                ),
                                label: Text(
                                  user.isActive
                                      ? languageCubit.getLocalizedText(
                                          korean: '비활성화',
                                          english: 'Deactivate',
                                        )
                                      : languageCubit.getLocalizedText(
                                          korean: '활성화',
                                          english: 'Activate',
                                        ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: user.isActive
                                      ? colorScheme.errorContainer
                                      : Colors.green.shade100,
                                  foregroundColor: user.isActive
                                      ? colorScheme.onErrorContainer
                                      : Colors.green.shade900,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _toggleUserStatus(user);
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Delete button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete_outline),
                            label: Text(
                              languageCubit.getLocalizedText(
                                korean: '사용자 삭제',
                                english: 'Delete User',
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              side: BorderSide(color: colorScheme.error),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteUser(user);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  String _formatDate(String isoString) {
    if (isoString.isEmpty) return 'Unknown';
    
    try {
      final date = DateTime.parse(isoString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageCubit = context.watch<LanguagePreferenceCubit>();
    
    return BlocConsumer<UserManagementCubit, UserManagementState>(
      listener: (context, state) {
        if (state is UserActionSuccess) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is UserManagementError) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
        
        // Update filtered users list when users are loaded
        if (state is UsersLoaded && _filteredUsers.isEmpty) {
          _filteredUsers = state.users;
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              languageCubit.getLocalizedText(
                korean: '사용자 관리',
                english: 'User Management',
              ),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            backgroundColor: colorScheme.surface,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadUsers,
                tooltip: languageCubit.getLocalizedText(
                  korean: '새로고침',
                  english: 'Refresh',
                ),
              ),
            ],
          ),
          body: state is UserManagementLoading
              ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
              : Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: languageCubit.getLocalizedText(
                            korean: '사용자 검색',
                            english: 'Search users',
                          ),
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    if (state is UsersLoaded) {
                                      _filterUsers(state.users, '');
                                    }
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          if (state is UsersLoaded) {
                            _filterUsers(state.users, value);
                          }
                        },
                      ),
                    ),
                    
                    // Stats summary
                    if (state is UsersLoaded) _buildStatsSummary(state.users, theme, colorScheme),
                    
                    // User list
                    Expanded(
                      child: _filteredUsers.isEmpty
                          ? Center(
                              child: Text(
                                languageCubit.getLocalizedText(
                                  korean: '사용자를 찾을 수 없습니다',
                                  english: 'No users found',
                                ),
                                style: theme.textTheme.bodyLarge,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) => _buildUserCard(
                                _filteredUsers[index],
                                theme,
                                colorScheme,
                                languageCubit
                              ),
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }
  
  Widget _buildStatsSummary(List<UserManagementModel> users, ThemeData theme, ColorScheme colorScheme) {
    final totalUsers = users.length;
    final activeUsers = users.where((user) => user.isActive).length;
    final adminUsers = users.where((user) => user.isAdmin).length;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                Icons.people,
                totalUsers.toString(),
                languageCubit.getLocalizedText(
                  korean: '전체 사용자',
                  english: 'Total Users',
                ),
                colorScheme.primary,
                theme,
              ),
              _buildStatItem(
                Icons.check_circle,
                activeUsers.toString(),
                languageCubit.getLocalizedText(
                  korean: '활성 사용자',
                  english: 'Active Users',
                ),
                Colors.green,
                theme,
              ),
              _buildStatItem(
                Icons.admin_panel_settings,
                adminUsers.toString(),
                languageCubit.getLocalizedText(
                  korean: '관리자',
                  english: 'Admins',
                ),
                colorScheme.secondary,
                theme,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatItem(IconData icon, String count, String label, Color color, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          count,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
  
  Widget _buildUserCard(UserManagementModel user, ThemeData theme, ColorScheme colorScheme, LanguagePreferenceCubit languageCubit) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showUserDetails(user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and avatar
              Row(
                children: [
                  Hero(
                    tag: 'user-avatar-${user.id}',
                    child: CircleAvatar(
                      backgroundColor: user.isAdmin
                          ? colorScheme.secondaryContainer
                          : user.isActive
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                      backgroundImage: user.photoUrl != null 
                          ? NetworkImage(user.photoUrl!) 
                          : null,
                      child: user.photoUrl == null
                          ? Icon(
                              user.isAdmin
                                  ? Icons.admin_panel_settings
                                  : Icons.person,
                              color: user.isAdmin
                                  ? colorScheme.onSecondaryContainer
                                  : user.isActive
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurfaceVariant,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name != 'Unknown' ? user.name : user.id,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.email != 'Unknown' ? user.email : 'Email unknown',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Status chips
                  Wrap(
                    spacing: 4,
                    children: [
                      if (user.isAdmin)
                        Chip(
                          label: Text(
                            languageCubit.getLocalizedText(
                              korean: '관리자',
                              english: 'Admin',
                            ),
                            style: TextStyle(
                              color: colorScheme.onSecondaryContainer,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: colorScheme.secondaryContainer,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      Chip(
                        label: Text(
                          user.isActive
                              ? languageCubit.getLocalizedText(
                                  korean: '활성',
                                  english: 'Active',
                                )
                              : languageCubit.getLocalizedText(
                                  korean: '비활성',
                                  english: 'Inactive',
                                ),
                          style: TextStyle(
                            color: user.isActive
                                ? Colors.white
                                : colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: user.isActive
                            ? Colors.green
                            : colorScheme.surfaceContainerHighest,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Action row - simplified for card view
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date info
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatDate(user.createdAt),
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Info button
                      IconButton(
                        icon: Icon(
                          Icons.info_outline,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: () => _showUserDetails(user),
                        tooltip: languageCubit.getLocalizedText(
                          korean: '세부 정보',
                          english: 'User Details',
                        ),
                      ),
                      
                      // Reset password button (icon only in card view)
                      IconButton(
                        icon: Icon(
                          Icons.lock_reset,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: () => _resetPassword(user),
                        tooltip: languageCubit.getLocalizedText(
                          korean: '비밀번호 재설정',
                          english: 'Reset Password',
                        ),
                      ),
                      
                      // Toggle status button (icon only in card view)
                      IconButton(
                        icon: Icon(
                          user.isActive ? Icons.block : Icons.check_circle,
                          color: user.isActive ? colorScheme.error : Colors.green,
                          size: 20,
                        ),
                        onPressed: () => _toggleUserStatus(user),
                        tooltip: user.isActive
                            ? languageCubit.getLocalizedText(
                                korean: '비활성화',
                                english: 'Deactivate',
                              )
                            : languageCubit.getLocalizedText(
                                korean: '활성화',
                                english: 'Activate',
                              ),
                      ),
                      
                      // Delete button (icon only in card view)
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: colorScheme.error,
                          size: 20,
                        ),
                        onPressed: () => _deleteUser(user),
                        tooltip: languageCubit.getLocalizedText(
                          korean: '삭제',
                          english: 'Delete',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}