import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';
import 'package:korean_language_app/core/presentation/snackbar/bloc/snackbar_cubit.dart';
import 'package:korean_language_app/features/tests/data/models/test_question.dart';
import 'package:korean_language_app/features/tests/presentation/bloc/test_session/test_session_cubit.dart';
import 'package:korean_language_app/features/tests/presentation/bloc/tests_cubit.dart';
import 'package:korean_language_app/features/tests/presentation/pages/test_result_page.dart';

class TestTakingPage extends StatefulWidget {
  final String testId;

  const TestTakingPage({super.key, required this.testId});

  @override
  State<TestTakingPage> createState() => _TestTakingPageState();
}

class _TestTakingPageState extends State<TestTakingPage> {
  int? _selectedAnswerIndex;
  bool _showingExplanation = false;
  
  TestSessionCubit get _sessionCubit => context.read<TestSessionCubit>();
  TestsCubit get _testsCubit => context.read<TestsCubit>();
  LanguagePreferenceCubit get _languageCubit => context.read<LanguagePreferenceCubit>();
  SnackBarCubit get _snackBarCubit => context.read<SnackBarCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndStartTest();
    });
  }

  Future<void> _loadAndStartTest() async {
    await _testsCubit.loadTestById(widget.testId);
    
    final testsState = _testsCubit.state;
    if (testsState.selectedTest != null) {
      _sessionCubit.startTest(testsState.selectedTest!);
    } else {
      _snackBarCubit.showErrorLocalized(
        korean: '시험을 찾을 수 없습니다',
        english: 'Test not found',
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TestSessionCubit, TestSessionState>(
      listener: (context, state) {
        if (state is TestSessionCompleted) {
          // Navigate to results page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => TestResultPage(result: state.result),
            ),
          );
        } else if (state is TestSessionError) {
          _snackBarCubit.showErrorLocalized(
            korean: state.error ?? '오류가 발생했습니다',
            english: state.error ?? 'An error occurred',
          );
        }
      },
      builder: (context, state) {
        if (state is TestSessionInProgress) {
          return _buildTestInProgress(state.session);
        } else if (state is TestSessionPaused) {
          return _buildTestPaused(state.session);
        } else if (state is TestSessionSubmitting) {
          return _buildSubmittingTest();
        } else {
          return _buildLoadingTest();
        }
      },
    );
  }

  Widget _buildLoadingTest() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _languageCubit.getLocalizedText(
                korean: '시험을 불러오는 중...',
                english: 'Loading test...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittingTest() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _languageCubit.getLocalizedText(
                korean: '답안을 제출하는 중...',
                english: 'Submitting answers...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestPaused(TestSession session) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(session.test.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pause_circle_outline,
              size: 80,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              _languageCubit.getLocalizedText(
                korean: '시험이 일시정지되었습니다',
                english: 'Test Paused',
              ),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _languageCubit.getLocalizedText(
                korean: '계속하려면 재개 버튼을 누르세요',
                english: 'Tap resume to continue the test',
              ),
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => _showExitConfirmation(),
                  child: Text(
                    _languageCubit.getLocalizedText(
                      korean: '시험 종료',
                      english: 'Exit Test',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _sessionCubit.resumeTest(),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    _languageCubit.getLocalizedText(
                      korean: '재개',
                      english: 'Resume',
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

  Widget _buildTestInProgress(TestSession session) {
    final currentQuestion = session.test.questions[session.currentQuestionIndex];
    final savedAnswer = session.getAnswerForQuestion(session.currentQuestionIndex);
    
    // Set selected answer if we have a saved answer
    if (savedAnswer != null && _selectedAnswerIndex != savedAnswer.selectedAnswerIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedAnswerIndex = savedAnswer.selectedAnswerIndex;
        });
      });
    }

    return Scaffold(
      appBar: _buildTestAppBar(session),
      body: Column(
        children: [
          _buildTestProgress(session),
          if (session.hasTimeLimit) _buildTimeRemaining(session),
          Expanded(
            child: _buildQuestionContent(session, currentQuestion),
          ),
          _buildTestNavigation(session),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTestAppBar(TestSession session) {
    return AppBar(
      title: Text(session.test.title),
      leading: IconButton(
        icon: const Icon(Icons.pause),
        onPressed: () => _sessionCubit.pauseTest(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(),
        ),
      ],
    );
  }

  Widget _buildTestProgress(TestSession session) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_languageCubit.getLocalizedText(korean: '문제', english: 'Question')} ${session.currentQuestionIndex + 1}/${session.totalQuestions}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_languageCubit.getLocalizedText(korean: '답변 완료', english: 'Answered')}: ${session.answeredQuestionsCount}/${session.totalQuestions}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: session.progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRemaining(TestSession session) {
    final theme = Theme.of(context);
    final isLowTime = session.timeRemaining != null && session.timeRemaining! < 300; // 5 minutes
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isLowTime ? Colors.red.withValues(alpha: 0.1) : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer,
            size: 20,
            color: isLowTime ? Colors.red : theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '${_languageCubit.getLocalizedText(korean: '남은 시간', english: 'Time remaining')}: ${session.formattedTimeRemaining}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isLowTime ? Colors.red : theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(TestSession session, TestQuestion question) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question image if available
          if (question.imageUrl != null && question.imageUrl!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: question.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
            ),
          
          // Question text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              question.question,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Answer options
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = _selectedAnswerIndex == index;
            final savedAnswer = session.getAnswerForQuestion(session.currentQuestionIndex);
            final isAnswered = savedAnswer != null;
            final isCorrect = index == question.correctAnswerIndex;
            
            Color? backgroundColor;
            Color? borderColor;
            Color? textColor;
            
            if (_showingExplanation && isAnswered) {
              if (index == savedAnswer.selectedAnswerIndex) {
                backgroundColor = savedAnswer.isCorrect 
                    ? Colors.green.withValues(alpha: 0.1) 
                    : Colors.red.withValues(alpha: 0.1);
                borderColor = savedAnswer.isCorrect ? Colors.green : Colors.red;
                textColor = savedAnswer.isCorrect ? Colors.green[800] : Colors.red[800];
              } else if (isCorrect) {
                backgroundColor = Colors.green.withValues(alpha: 0.1);
                borderColor = Colors.green;
                textColor = Colors.green[800];
              }
            } else if (isSelected) {
              backgroundColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
              borderColor = Theme.of(context).colorScheme.primary;
              textColor = Theme.of(context).colorScheme.primary;
            }
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _showingExplanation ? null : () {
                    setState(() {
                      _selectedAnswerIndex = index;
                      _showingExplanation = false;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor ?? Colors.grey.withValues(alpha: 0.3),
                        width: borderColor != null ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: textColor ?? Colors.grey,
                              width: 2,
                            ),
                            color: isSelected && !_showingExplanation
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                          ),
                          child: isSelected && !_showingExplanation
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${String.fromCharCode(65 + index)}. $option',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (_showingExplanation && isCorrect)
                          Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                        if (_showingExplanation && !isCorrect && index == savedAnswer?.selectedAnswerIndex)
                          Icon(Icons.cancel, color: Colors.red[600], size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
          
          // Answer button
          if (_selectedAnswerIndex != null && !_showingExplanation)
            Container(
              margin: const EdgeInsets.only(top: 16),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _answerQuestion(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _languageCubit.getLocalizedText(
                    korean: '답안 선택',
                    english: 'Select Answer',
                  ),
                ),
              ),
            ),
          
          // Explanation
          if (_showingExplanation && question.explanation != null)
            Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        _languageCubit.getLocalizedText(
                          korean: '설명',
                          english: 'Explanation',
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.explanation!,
                    style: const TextStyle(height: 1.4),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTestNavigation(TestSession session) {
    final theme = Theme.of(context);
    final isFirstQuestion = session.currentQuestionIndex == 0;
    final isLastQuestion = session.currentQuestionIndex == session.totalQuestions - 1;
    final isAnswered = session.isQuestionAnswered(session.currentQuestionIndex);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isFirstQuestion ? null : () {
                setState(() {
                  _selectedAnswerIndex = null;
                  _showingExplanation = false;
                });
                _sessionCubit.previousQuestion();
              },
              icon: const Icon(Icons.arrow_back),
              label: Text(
                _languageCubit.getLocalizedText(
                  korean: '이전',
                  english: 'Previous',
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Next/Finish button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                if (isLastQuestion) {
                  _showFinishConfirmation(session);
                } else {
                  setState(() {
                    _selectedAnswerIndex = null;
                    _showingExplanation = false;
                  });
                  _sessionCubit.nextQuestion();
                }
              },
              icon: Icon(isLastQuestion ? Icons.check : Icons.arrow_forward),
              label: Text(
                isLastQuestion
                    ? _languageCubit.getLocalizedText(korean: '시험 완료', english: 'Finish Test')
                    : _languageCubit.getLocalizedText(korean: '다음', english: 'Next'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _answerQuestion() {
    if (_selectedAnswerIndex == null) return;
    
    _sessionCubit.answerQuestion(_selectedAnswerIndex!);
    setState(() {
      _showingExplanation = true;
    });
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _languageCubit.getLocalizedText(
            korean: '시험 종료',
            english: 'Exit Test',
          ),
        ),
        content: Text(
          _languageCubit.getLocalizedText(
            korean: '정말로 시험을 종료하시겠습니까? 진행 상황이 저장되지 않습니다.',
            english: 'Are you sure you want to exit the test? Your progress will not be saved.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _languageCubit.getLocalizedText(
                korean: '취소',
                english: 'Cancel',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sessionCubit.cancelTest();
              context.pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              _languageCubit.getLocalizedText(
                korean: '종료',
                english: 'Exit',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinishConfirmation(TestSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _languageCubit.getLocalizedText(
            korean: '시험 완료',
            english: 'Complete Test',
          ),
        ),
        content: Text(
          _languageCubit.getLocalizedText(
            korean: '시험을 완료하시겠습니까? 답안을 제출한 후에는 수정할 수 없습니다.\n\n답변 완료: ${session.answeredQuestionsCount}/${session.totalQuestions}',
            english: 'Are you ready to complete the test? You cannot change your answers after submission.\n\nAnswered: ${session.answeredQuestionsCount}/${session.totalQuestions}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _languageCubit.getLocalizedText(
                korean: '취소',
                english: 'Cancel',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sessionCubit.completeTest();
            },
            child: Text(
              _languageCubit.getLocalizedText(
                korean: '완료',
                english: 'Complete',
              ),
            ),
          ),
        ],
      ),
    );
  }
}