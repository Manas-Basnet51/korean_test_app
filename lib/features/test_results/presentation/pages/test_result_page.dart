import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';
import 'package:korean_language_app/core/models/test_result.dart';

class TestResultPage extends StatelessWidget {
  final TestResult result;

  const TestResultPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageCubit = context.read<LanguagePreferenceCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageCubit.getLocalizedText(
            korean: '시험 결과',
            english: 'Test Results',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/tests'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildResultHeader(context, theme, colorScheme, languageCubit),
            const SizedBox(height: 24),
            _buildScoreCard(context, theme, colorScheme, languageCubit),
            const SizedBox(height: 24),
            _buildStatisticsCard(context, theme, colorScheme, languageCubit),
            const SizedBox(height: 24),
            _buildDetailedResults(context, theme, colorScheme, languageCubit),
            const SizedBox(height: 32),
            _buildActionButtons(context, languageCubit),
          ],
        ),
      ),
    );
  }

  Widget _buildResultHeader(BuildContext context, ThemeData theme, ColorScheme colorScheme, LanguagePreferenceCubit languageCubit) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: result.isPassed
              ? [Colors.green.withValues(alpha: 0.1), Colors.green.withValues(alpha: 0.05)]
              : [Colors.red.withValues(alpha: 0.1), Colors.red.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: result.isPassed 
              ? Colors.green.withValues(alpha: 0.3) 
              : Colors.red.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            result.isPassed ? Icons.celebration : Icons.sentiment_dissatisfied,
            size: 64,
            color: result.isPassed ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            result.isPassed
                ? languageCubit.getLocalizedText(korean: '축하합니다!', english: 'Congratulations!')
                : languageCubit.getLocalizedText(korean: '아쉽네요!', english: 'Try Again!'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: result.isPassed ? Colors.green[800] : Colors.red[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.testTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            result.isPassed
                ? languageCubit.getLocalizedText(
                    korean: '시험에 합격하셨습니다!',
                    english: 'You have passed the test!',
                  )
                : languageCubit.getLocalizedText(
                    korean: '더 공부하고 다시 도전해보세요!',
                    english: 'Study more and try again!',
                  ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, ThemeData theme, ColorScheme colorScheme, LanguagePreferenceCubit languageCubit) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              languageCubit.getLocalizedText(
                korean: '최종 점수',
                english: 'Final Score',
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Score circle
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                children: [
                  Center(
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: result.score / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          result.isPassed ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${result.score}%',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: result.isPassed ? Colors.green : Colors.red,
                          ),
                        ),
                        Text(
                          result.resultSummary,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildScoreDetail(
                  languageCubit.getLocalizedText(korean: '정답', english: 'Correct'),
                  '${result.correctAnswers}',
                  Colors.green,
                  theme,
                ),
                _buildScoreDetail(
                  languageCubit.getLocalizedText(korean: '오답', english: 'Incorrect'),
                  '${result.totalQuestions - result.correctAnswers}',
                  Colors.red,
                  theme,
                ),
                _buildScoreDetail(
                  languageCubit.getLocalizedText(korean: '시간', english: 'Time'),
                  result.formattedDuration,
                  colorScheme.primary,
                  theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDetail(String label, String value, Color color, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard(BuildContext context, ThemeData theme, ColorScheme colorScheme, LanguagePreferenceCubit languageCubit) {
    final averageTimePerQuestion = result.totalQuestions > 0 
        ? result.totalTimeSpent / result.totalQuestions 
        : 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              languageCubit.getLocalizedText(
                korean: '통계',
                english: 'Statistics',
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildStatRow(
              languageCubit.getLocalizedText(korean: '시작 시간', english: 'Started'),
              _formatDateTime(result.startedAt),
              Icons.schedule,
              theme,
            ),
            _buildStatRow(
              languageCubit.getLocalizedText(korean: '완료 시간', english: 'Completed'),
              _formatDateTime(result.completedAt),
              Icons.check_circle_outline,
              theme,
            ),
            _buildStatRow(
              languageCubit.getLocalizedText(korean: '총 소요 시간', english: 'Total Time'),
              result.formattedDuration,
              Icons.timer,
              theme,
            ),
            _buildStatRow(
              languageCubit.getLocalizedText(korean: '문제당 평균 시간', english: 'Avg. Time per Question'),
              '${averageTimePerQuestion.toStringAsFixed(1)}초',
              Icons.av_timer,
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedResults(BuildContext context, ThemeData theme, ColorScheme colorScheme, LanguagePreferenceCubit languageCubit) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              languageCubit.getLocalizedText(
                korean: '상세 결과',
                english: 'Detailed Results',
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ...result.answers.asMap().entries.map((entry) {
              final index = entry.key;
              final answer = entry.value;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: answer.isCorrect 
                      ? Colors.green.withValues(alpha: 0.1) 
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: answer.isCorrect 
                        ? Colors.green.withValues(alpha: 0.3) 
                        : Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: answer.isCorrect ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${languageCubit.getLocalizedText(korean: '문제', english: 'Question')} ${index + 1}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${languageCubit.getLocalizedText(korean: '소요 시간', english: 'Time')}: ${answer.timeSpent}초',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      answer.isCorrect ? Icons.check_circle : Icons.cancel,
                      color: answer.isCorrect ? Colors.green : Colors.red,
                      size: 24,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, LanguagePreferenceCubit languageCubit) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/tests'),
            icon: const Icon(Icons.quiz),
            label: Text(
              languageCubit.getLocalizedText(
                korean: '다른 시험 보기',
                english: 'Take Another Test',
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/tests/results'),
            icon: const Icon(Icons.history),
            label: Text(
              languageCubit.getLocalizedText(
                korean: '내 결과 기록',
                english: 'View My Results',
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => _shareResult(context),
            icon: const Icon(Icons.share),
            label: Text(
              languageCubit.getLocalizedText(
                korean: '결과 공유',
                english: 'Share Result',
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _shareResult(BuildContext context) {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing functionality coming soon')),
    );
  }
}