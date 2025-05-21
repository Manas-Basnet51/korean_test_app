import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:korean_language_app/core/routes/app_router.dart';
import 'package:korean_language_app/features/admin/domain/entities/admin_user.dart';
import 'package:korean_language_app/features/admin/presentation/bloc/admin_permission_cubit.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';
import 'package:korean_language_app/core/presentation/snackbar/bloc/snackbar_cubit.dart';

class AdminManagementPage extends StatefulWidget {
  const AdminManagementPage({super.key});

  @override
  State<AdminManagementPage> createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<AdminManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<AdminUser> _adminUsers = [];
  List<AdminUser> _filteredAdminUsers = [];

  late AdminPermissionCubit _adminPermissionCubit;
  
  @override
  void initState() {
    _adminPermissionCubit = context.read<AdminPermissionCubit>();
    super.initState();
    _loadAdminUsers();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAdminUsers() async {
    setState(() => _isLoading = true);
    
    try {
      final firestore = FirebaseFirestore.instance;
      const String collectionPath = 'admin_users';
      
      final snapshot = await firestore.collection(collectionPath).get();
      final admins = await Future.wait(snapshot.docs.map(_convertDocToAdminUser));
      
      setState(() {
        _adminUsers = admins;
        _filteredAdminUsers = admins;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error loading admin users: ${e.toString()}');
    }
  }
  
  Future<AdminUser> _convertDocToAdminUser(DocumentSnapshot doc) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final userDoc = await firestore.collection('users').doc(doc.id).get();
      final userData = userDoc.data();
      
      return AdminUser(
        id: doc.id,
        email: userData?['email'] ?? 'Unknown',
        name: userData?['name'] ?? 'Unknown',
        isActive: (doc.data() as Map<String, dynamic>?)?['isActive'] ?? true,
        createdAt: (doc.data() as Map<String, dynamic>?)?['createdAt'] ?? '',
      );
    } catch (_) {
      // If user document doesn't exist, just use admin document
      return AdminUser(
        id: doc.id,
        email: 'Unknown',
        name: 'Unknown',
        isActive: (doc.data() as Map<String, dynamic>?)?['isActive'] ?? true,
        createdAt: (doc.data() as Map<String, dynamic>?)?['createdAt'] ?? '',
      );
    }
  }
  
  void _filterAdmins(String query) {
    final lowercaseQuery = query.toLowerCase();
    final filteredList = _adminUsers.where((admin) {
      return admin.name.toLowerCase().contains(lowercaseQuery) ||
             admin.email.toLowerCase().contains(lowercaseQuery) ||
             admin.id.toLowerCase().contains(lowercaseQuery);
    }).toList();
    
    setState(() => _filteredAdminUsers = filteredList);
  }
  
  Future<void> _toggleAdminStatus(AdminUser admin) async {
    setState(() => _isLoading = true);
    
    try {
      final firestore = FirebaseFirestore.instance;
      const String collectionPath = 'admin_users';
      
      // Toggle active status
      await firestore.collection(collectionPath).doc(admin.id).update({
        'isActive': !admin.isActive,
      });
      
      await _loadAdminUsers();
      _showSuccess('Admin status updated successfully');
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error updating admin status: ${e.toString()}');
    }
  }
  
  Future<void> _removeAdmin(AdminUser admin) async {
    final shouldDelete = await _showConfirmationDialog(admin);
    if (shouldDelete != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      final firestore = FirebaseFirestore.instance;
      const String collectionPath = 'admin_users';
      
      await firestore.collection(collectionPath).doc(admin.id).delete();
      await _loadAdminUsers();
      
      // Clear any cached status
      _adminPermissionCubit.clearAdminCache();
      _showSuccess('Admin removed successfully');
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error removing admin: ${e.toString()}');
    }
  }
  
  Future<bool?> _showConfirmationDialog(AdminUser admin) {
    final languageCubit = context.read<LanguagePreferenceCubit>();
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          languageCubit.getLocalizedText(
            korean: '관리자 제거',
            english: 'Remove Admin',
            hardWords: ['관리자'],
          ),
        ),
        content: Text(
          languageCubit.getLocalizedText(
            korean: '${admin.email}의 관리자 권한을 제거하시겠습니까?',
            english: 'Are you sure you want to remove admin privileges from ${admin.email}?',
            hardWords: ['관리자', '권한'],
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
                korean: '제거',
                english: 'Remove',
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showSuccess(String message) {
    final snackBarCubit = context.read<SnackBarCubit>();
    
    snackBarCubit.showSuccessLocalized(
      korean: _getKoreanMessage(message),
      english: message,
    );
  }

  void _showError(String message) {
    final snackBarCubit = context.read<SnackBarCubit>();
    
    snackBarCubit.showErrorLocalized(
      korean: _getKoreanMessage(message),
      english: message,
    );
  }

  // Simple translation mapping for admin-related messages
  String _getKoreanMessage(String englishMessage) {
    final translations = {
      'Admin status updated successfully': '관리자 상태가 성공적으로 업데이트되었습니다',
      'Admin removed successfully': '관리자가 성공적으로 제거되었습니다',
      'Error loading admin users': '관리자 사용자 로드 중 오류',
      'Error updating admin status': '관리자 상태 업데이트 중 오류',
      'Error removing admin': '관리자 제거 중 오류',
    };
    
    // Try to find exact match
    if (translations.containsKey(englishMessage)) {
      return translations[englishMessage]!;
    }
    
    // Try to find partial match for error messages
    for (var entry in translations.entries) {
      if (englishMessage.contains(entry.key)) {
        return '${entry.value}: ${englishMessage.substring(entry.key.length)}';
      }
    }
    
    // Fallback
    return englishMessage;
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
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageCubit = context.watch<LanguagePreferenceCubit>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageCubit.getLocalizedText(
            korean: '관리자 관리',
            english: 'Admin Management',
            hardWords: ['관리자'],
          ),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdminUsers,
            tooltip: languageCubit.getLocalizedText(
              korean: '새로고침',
              english: 'Refresh',
            ),
          ),
        ],
      ),
      body: _isLoading
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
                        korean: '관리자 검색',
                        english: 'Search admins',
                        hardWords: ['관리자'],
                      ),
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterAdmins('');
                              },
                            )
                          : null,
                    ),
                    onChanged: _filterAdmins,
                  ),
                ),
                
                // Admin list
                Expanded(
                  child: _filteredAdminUsers.isEmpty
                      ? Center(
                          child: Text(
                            languageCubit.getLocalizedText(
                              korean: '관리자를 찾을 수 없습니다',
                              english: 'No admin users found',
                              hardWords: ['관리자'],
                            ),
                            style: theme.textTheme.bodyLarge,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredAdminUsers.length,
                          itemBuilder: (context, index) => _buildAdminCard(
                            _filteredAdminUsers[index],
                            theme,
                            colorScheme,
                            languageCubit
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.adminSignup),
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        tooltip: languageCubit.getLocalizedText(
          korean: '관리자 추가',
          english: 'Add Admin',
          hardWords: ['관리자'],
        ),
        child: const Icon(Icons.person_add),
      ),
    );
  }
  
  Widget _buildAdminCard(AdminUser admin, ThemeData theme, ColorScheme colorScheme, LanguagePreferenceCubit languageCubit) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and avatar
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: admin.isActive
                      ? colorScheme.secondaryContainer
                      : colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: admin.isActive
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        admin.name != 'Unknown' ? admin.name : admin.id,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        admin.email != 'Unknown' ? admin.email : 'Email unknown',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status chip
                Chip(
                  label: Text(
                    admin.isActive
                        ? languageCubit.getLocalizedText(
                            korean: '활성',
                            english: 'Active',
                          )
                        : languageCubit.getLocalizedText(
                            korean: '비활성',
                            english: 'Inactive',
                          ),
                    style: TextStyle(
                      color: admin.isActive
                          ? Colors.white
                          : colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: admin.isActive
                      ? Colors.green
                      : colorScheme.surfaceContainerHighest,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Created date
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  "${languageCubit.getLocalizedText(
                    korean: '생성일',
                    english: 'Created',
                  )}: ${_formatDate(admin.createdAt)}",
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Toggle status button
                OutlinedButton.icon(
                  icon: Icon(
                    admin.isActive
                        ? Icons.block
                        : Icons.check_circle,
                    size: 18,
                  ),
                  label: Text(
                    admin.isActive
                        ? languageCubit.getLocalizedText(
                            korean: '비활성화',
                            english: 'Deactivate',
                          )
                        : languageCubit.getLocalizedText(
                            korean: '활성화',
                            english: 'Activate',
                          ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: admin.isActive
                        ? colorScheme.error
                        : Colors.green,
                    side: BorderSide(
                      color: admin.isActive
                          ? colorScheme.error
                          : Colors.green,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => _toggleAdminStatus(admin),
                ),
                const SizedBox(width: 8),
                // Remove button
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                  ),
                  label: Text(
                    languageCubit.getLocalizedText(
                      korean: '제거',
                      english: 'Remove',
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => _removeAdmin(admin),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}