import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';
import 'package:korean_language_app/core/routes/app_router.dart';
import 'package:korean_language_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:korean_language_app/features/test_results/data/models/test_result.dart';
import 'package:korean_language_app/features/test_results/presentation/bloc/test_results_cubit.dart';

class TestResultsHistoryPage extends StatefulWidget {
  const TestResultsHistoryPage({super.key});

  @override
  State<TestResultsHistoryPage> createState() => _TestResultsHistoryPageState();
}

class _TestResultsHistoryPageState extends State<TestResultsHistoryPage> {
  List<TestResult> _results = [];
  bool _isLoading = true;
  String? _error;
  
  TestResultsCubit get _testResultsCubit => context.read<TestResultsCubit>();
  LanguagePreferenceCubit get _languageCubit => context.read<LanguagePreferenceCubit>();
  AuthCubit get _authCubit => context.read<AuthCubit>();

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = _authCubit.state;
      if (authState is! Authenticated) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Get test results using TestResultsCubit
      final results = await _testResultsCubit.getTestResultsWithHandling();
      
      setState(() {
        _results = results;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _languageCubit.getLocalizedText(
            korean: '내 시험 결과',
            english: 'My Test Results',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadResults,
            tooltip: _languageCubit.getLocalizedText(
              korean: '새로고침',
              english: 'Refresh',
            ),
          ),
        ],
      ),
      body: BlocListener<TestResultsCubit, TestResultsState>(
        listener: (context, state) {
          if (state.currentOperation.status == TestResultsOperationStatus.completed &&
              state.currentOperation.type == TestResultsOperationType.loadResults) {
            setState(() {
              _results = state.results;
              _isLoading = false;
              _error = null;
            });
          } else if (state.currentOperation.status == TestResultsOperationStatus.failed) {
            setState(() {
              _error = state.error ?? 'Failed to load results';
              _isLoading = false;
            });
          }
        },
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorView();
    }

    if (_results.isEmpty) {
      return _buildEmptyView();
    }

    return _buildResultsList();
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              _languageCubit.getLocalizedText(
                korean: '결과를 불러올 수 없습니다',
                english: 'Failed to load results',
              ),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadResults,
              icon: const Icon(Icons.refresh),
              label: Text(
                _languageCubit.getLocalizedText(
                  korean: '다시 시도',
                  english: 'Try Again',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _languageCubit.getLocalizedText(
                korean: '아직 시험 결과가 없습니다',
                english: 'No test results yet',
              ),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _languageCubit.getLocalizedText(
                korean: '시험을 치르면 결과가 여기에 표시됩니다',
                english: 'Take some tests and your results will appear here',
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go(Routes.tests),
              icon: const Icon(Icons.quiz),
              label: Text(
                _languageCubit.getLocalizedText(
                  korean: '시험 보러 가기',
                  english: 'Take a Test',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return RefreshIndicator(
      onRefresh: _loadResults,
      child: Column(
        children: [
          _buildStatsHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                return _buildResultCard(result);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    final totalTests = _results.length;
    final passedTests = _results.where((r) => r.isPassed).length;
    final averageScore = totalTests > 0 
        ? _results.map((r) => r.score).reduce((a, b) => a + b) / totalTests
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            _languageCubit.getLocalizedText(
              korean: '통계',
              english: 'Statistics',
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  _languageCubit.getLocalizedText(korean: '총 시험', english: 'Total Tests'),
                  totalTests.toString(),
                  Icons.quiz,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  _languageCubit.getLocalizedText(korean: '합격', english: 'Passed'),
                  passedTests.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  _languageCubit.getLocalizedText(korean: '평균 점수', english: 'Avg Score'),
                  '${averageScore.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResultCard(TestResult result) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _viewResultDetails(result),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      result.testTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: result.isPassed 
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: result.isPassed 
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      result.isPassed 
                          ? _languageCubit.getLocalizedText(korean: '합격', english: 'PASSED')
                          : _languageCubit.getLocalizedText(korean: '불합격', english: 'FAILED'),
                      style: TextStyle(
                        color: result.isPassed ? Colors.green[800] : Colors.red[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  _buildResultInfo(
                    Icons.percent,
                    '${result.score}%',
                    _languageCubit.getLocalizedText(korean: '점수', english: 'Score'),
                    result.isPassed ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 16),
                  _buildResultInfo(
                    Icons.check_circle_outline,
                    '${result.correctAnswers}/${result.totalQuestions}',
                    _languageCubit.getLocalizedText(korean: '정답', english: 'Correct'),
                    Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _buildResultInfo(
                    Icons.timer,
                    result.formattedDuration,
                    _languageCubit.getLocalizedText(korean: '시간', english: 'Time'),
                    Colors.orange,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(result.completedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultInfo(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return _languageCubit.getLocalizedText(korean: '오늘', english: 'Today');
    } else if (difference == 1) {
      return _languageCubit.getLocalizedText(korean: '어제', english: 'Yesterday');
    } else if (difference < 7) {
      return _languageCubit.getLocalizedText(korean: '$difference일 전', english: '$difference days ago');
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _viewResultDetails(TestResult result) {
    context.push(Routes.testResult, extra: result);
  }
}