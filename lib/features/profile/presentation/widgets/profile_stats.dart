part of '../pages/profile_page.dart';


class ProfileStatsWidget extends StatelessWidget {
  final dynamic profileData;

  const ProfileStatsWidget({
    super.key,
    required this.profileData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageCubit = context.watch<LanguagePreferenceCubit>();
    
    // Use error boundary to prevent entire widget from failing
    return ErrorBoundary(
      fallbackBuilder: (context, error) => _buildErrorStats(context),
      child: Row(
        children: [
          // Tests stats
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
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Average score stats
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
            ),
          ),
          
          const SizedBox(width: 12),
          
          // TOPIK level stats
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
            ),
          ),
        ],
      ),
    );
  }

  // Fallback widget for error state
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

  // Stat card widget
  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues( alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues( alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}