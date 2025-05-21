import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/presentation/language_preference/enums/language_mode.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Get access to language preferences
    final languageCubit = context.watch<LanguagePreferenceCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageCubit.getLocalizedText(
            korean: '한국어 시험',
            english: 'Korean Test',
          ),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: colorScheme.onSurface),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: colorScheme.primary.withValues( alpha : 0.2),
                      child: Icon(Icons.person, size: 30, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageCubit.getLocalizedText(
                            korean: '안녕하세요!',
                            english: 'Hello!',
                            mixed: '안녕하세요! (Hello!)', 
                            hardWords: [],
                          ),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          languageCubit.getAppropriateText(
                            textVariants: {
                              LanguageMode.beginner: 'Continue your Korean journey',
                              LanguageMode.intermediate: 'Continue your 한국어 journey',
                              LanguageMode.advanced: '한국어 학습을 계속하세요',
                              LanguageMode.fullKorean: '한국어 학습을 계속하세요',
                            },
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Progress section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues( alpha : 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageCubit.getLocalizedText(
                          korean: '진행 상황',
                          english: 'Your Progress',
                          hardWords: [],
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: 0.68,
                        backgroundColor: colorScheme.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languageCubit.getLocalizedText(
                              korean: '68% 완료',
                              english: '68% Complete',
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              GoRouter.of(context).go('/tests/details/current');
                            },
                            child: Text(
                              languageCubit.getLocalizedText(
                                korean: '계속하기',
                                english: 'Continue',
                              ),
                              style: TextStyle(color: colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Categories section
                Text(
                  languageCubit.getLocalizedText(
                    korean: '시험 카테고리',
                    english: 'Test Categories',
                  ),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildCategoryCard(
                      context,
                      icon: Icons.speaker_notes,
                      title: 'TOPIK I',
                      subtitle: languageCubit.getLocalizedText(
                        korean: '초급 레벨',
                        english: 'Beginner level',
                      ),
                      onTap: () => GoRouter.of(context).go('/tests/details/topik1'),
                    ),
                    _buildCategoryCard(
                      context,
                      icon: Icons.school,
                      title: 'TOPIK II',
                      subtitle: languageCubit.getLocalizedText(
                        korean: '고급 레벨',
                        english: 'Advanced level',
                      ),
                      isSecondary: true,
                      onTap: () => GoRouter.of(context).go('/tests/details/topik2'),
                    ),
                    _buildCategoryCard(
                      context,
                      icon: Icons.headphones,
                      title: languageCubit.getLocalizedText(
                        korean: '듣기',
                        english: 'Listening',
                      ),
                      subtitle: languageCubit.getLocalizedText(
                        korean: '연습 시험',
                        english: 'Practice tests',
                      ),
                      isTertiary: true,
                      onTap: () => GoRouter.of(context).go('/tests/details/listening'),
                    ),
                    _buildCategoryCard(
                      context,
                      icon: Icons.edit,
                      title: languageCubit.getLocalizedText(
                        korean: '쓰기',
                        english: 'Writing',
                      ),
                      subtitle: languageCubit.getLocalizedText(
                        korean: '연습 시험',
                        english: 'Practice tests',
                      ),
                      onTap: () => GoRouter.of(context).go('/tests/details/writing'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Recent tests section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      languageCubit.getLocalizedText(
                        korean: '최근 시험',
                        english: 'Recent Tests',
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        GoRouter.of(context).go('/tests');
                      },
                      child: Text(
                        languageCubit.getLocalizedText(
                          korean: '모두 보기',
                          english: 'See All',
                        ), 
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                _buildRecentTestItem(
                  context,
                  title:   languageCubit.getLocalizedText(
                    korean: 'TOPIK I - 읽기 연습',
                    english: 'TOPIK I - Reading Practice',
                    hardWords: ['읽기 연습'],
                  ),
                  date: languageCubit.getLocalizedText(
                    korean: '2일 전',
                    english: '2 days ago',
                  ),
                  score: '85%',
                  onTap: () => GoRouter.of(context).go('/tests/details/recent1'),
                ),
                
                _buildRecentTestItem(
                  context,
                  title: languageCubit.getLocalizedText(
                    korean: '기본 문법 퀴즈',
                    english: 'Basic Grammar Quiz',
                  ),
                  date: languageCubit.getLocalizedText(
                    korean: '5일 전',
                    english: '5 days ago',
                  ),
                  score: '92%',
                  onTap: () => GoRouter.of(context).go('/tests/details/recent2'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCategoryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool isSecondary = false,
    bool isTertiary = false,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Determine colors based on category type
    Color bgColor;
    Color iconColor;
    
    if (isSecondary) {
      bgColor = colorScheme.secondary.withValues( alpha : 0.2);
      iconColor = colorScheme.secondary;
    } else if (isTertiary) {
      bgColor = colorScheme.tertiary.withValues( alpha : 0.2);
      iconColor = colorScheme.tertiary;
    } else {
      bgColor = colorScheme.primary.withValues( alpha : 0.2);
      iconColor = colorScheme.primary;
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: iconColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecentTestItem(
    BuildContext context, {
    required String title,
    required String date,
    required String score,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline.withValues( alpha : 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues( alpha : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.description, color: colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    date,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.tertiary.withValues( alpha : 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                score,
                style: TextStyle(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}