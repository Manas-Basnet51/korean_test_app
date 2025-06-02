part of '../pages/profile_page.dart';

class ProfileStatsWidget extends StatelessWidget {
  final dynamic profileData;
  final bool isOffline;

  const ProfileStatsWidget({
    super.key,
    required this.profileData,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageCubit = context.watch<LanguagePreferenceCubit>();
    
    return ErrorBoundary(
      fallbackBuilder: (context, error) => _buildErrorStats(context),
      child: Column(
        children: [
          // Offline indicator for stats section
          if (isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues( alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues( alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sync_disabled, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      languageCubit.getLocalizedText(
                        korean: '오프라인 모드 - 통계 동기화 불가',
                        english: 'Offline Mode - Stats sync unavailable',
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
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.check_circle,
                  title: languageCubit.getLocalizedText(
                    korean: '시험',
                    english: 'Tests',
                    hardWords: [],
                  ),
                  value: profileData.completedTests.toString(),
                  color: colorScheme.primary,
                  isOffline: isOffline,
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.star,
                  title: languageCubit.getLocalizedText(
                    korean: '평균 점수',
                    english: 'Avg. Score',
                    hardWords: [],
                  ),
                  value: '${profileData.averageScore.toStringAsFixed(1)}%',
                  color: colorScheme.tertiary,
                  isOffline: isOffline,
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.school,
                  title: languageCubit.getLocalizedText(
                    korean: 'TOPIK 레벨',
                    english: 'TOPIK Level',
                    hardWords: [],
                  ),
                  value: profileData.topikLevel,
                  color: colorScheme.secondary,
                  isOffline: isOffline,
                ),
              ),
            ],
          ),
          
          // Stats loading/error status
          if (profileData.currentOperation.type == ProfileOperationType.updateProfile)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildStatsOperationStatus(context),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsOperationStatus(BuildContext context) {
    final theme = Theme.of(context);
    final operation = profileData.currentOperation;
    
    if (operation.status == ProfileOperationStatus.inProgress) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues( alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Updating profile...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    } else if (operation.status == ProfileOperationStatus.failed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues( alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 14,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                operation.message ?? 'Update failed',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildErrorStats(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageCubit = context.watch<LanguagePreferenceCubit>();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues( alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withValues( alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              languageCubit.getLocalizedText(
                korean: '통계 데이터를 로드할 수 없습니다',
                english: 'Unable to load statistics',
                hardWords: ['통계 데이터'],
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<ProfileCubit>().loadProfile();
            },
            child: Text(
              languageCubit.getLocalizedText(
                korean: '다시 시도',
                english: 'Retry',
                hardWords: [],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isOffline = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isOffline 
            ? color.withValues( alpha: 0.05)
            : color.withValues( alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOffline 
              ? color.withValues( alpha: 0.1)
              : color.withValues( alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon, 
            color: isOffline ? color.withValues( alpha: 0.5) : color, 
            size: 28
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isOffline ? color.withValues( alpha: 0.7) : color,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isOffline 
                  ? colorScheme.onSurfaceVariant.withValues( alpha: 0.6)
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          if (isOffline)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                Icons.sync_disabled,
                size: 12,
                color: colorScheme.onSurfaceVariant.withValues( alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }
}