import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:korean_language_app/core/enums/question_type.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';
import 'package:korean_language_app/core/presentation/snackbar/bloc/snackbar_cubit.dart';
import 'package:korean_language_app/core/routes/app_router.dart';
import 'package:korean_language_app/core/models/test_question.dart';
import 'package:korean_language_app/features/tests/presentation/bloc/test_session/test_session_cubit.dart';
import 'package:korean_language_app/features/tests/presentation/bloc/tests_cubit.dart';

class TestTakingPage extends StatefulWidget {
  final String testId;

  const TestTakingPage({super.key, required this.testId});

  @override
  State<TestTakingPage> createState() => _TestTakingPageState();
}

class _TestTakingPageState extends State<TestTakingPage>
    with TickerProviderStateMixin {
  int? _selectedAnswerIndex;
  bool _showingExplanation = false;
  late AnimationController _progressAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _slideAnimation;
  Timer? _autoAdvanceTimer;

  TestSessionCubit get _sessionCubit => context.read<TestSessionCubit>();
  TestsCubit get _testsCubit => context.read<TestsCubit>();
  LanguagePreferenceCubit get _languageCubit =>
      context.read<LanguagePreferenceCubit>();
  SnackBarCubit get _snackBarCubit => context.read<SnackBarCubit>();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndStartTest();
    });
  }

  void _initializeAnimations() {
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _slideAnimationController.dispose();
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAndStartTest() async {
    await _testsCubit.loadTestById(widget.testId);

    final testsState = _testsCubit.state;
    if (testsState.selectedTest != null) {
      _sessionCubit.startTest(testsState.selectedTest!);
      _slideAnimationController.forward();
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
          context.push(Routes.testResult, extra: state.result);
        } else if (state is TestSessionError) {
          _snackBarCubit.showErrorLocalized(
            korean: state.error ?? '오류가 발생했습니다',
            english: state.error ?? 'An error occurred',
          );
        }
      },
      builder: (context, state) {
        if (state is TestSessionInitial) {
          return _buildLoadingScreen();
        }

        if (state is TestSessionInProgress || state is TestSessionPaused) {
          final session = state is TestSessionInProgress
              ? state.session
              : (state as TestSessionPaused).session;
          return _buildTestScreen(session, state is TestSessionPaused);
        }

        if (state is TestSessionSubmitting) {
          return _buildSubmittingScreen();
        }

        return _buildErrorScreen();
      },
    );
  }

  Widget _buildLoadingScreen() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _languageCubit.getLocalizedText(
                      korean: '시험을 준비하고 있습니다...',
                      english: 'Preparing your test...',
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittingScreen() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.upload,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _languageCubit.getLocalizedText(
                  korean: '답안을 제출하고 있습니다...',
                  english: 'Submitting your answers...',
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                _languageCubit.getLocalizedText(
                  korean: '오류가 발생했습니다',
                  english: 'Something went wrong',
                ),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: Text(
                  _languageCubit.getLocalizedText(
                    korean: '돌아가기',
                    english: 'Go Back',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestScreen(TestSession session, bool isPaused) {
    final question = session.test.questions[session.currentQuestionIndex];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTestHeader(session, isPaused),
            Expanded(
              child: AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - _slideAnimation.value)),
                    child: Opacity(
                      opacity: _slideAnimation.value,
                      child: _buildQuestionContent(session, question),
                    ),
                  );
                },
              ),
            ),
            _buildTestNavigation(session),
          ],
        ),
      ),
    );
  }

  Widget _buildTestHeader(TestSession session, bool isPaused) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _showExitConfirmation(),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceVariant,
                  foregroundColor: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.test.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _languageCubit.getLocalizedText(
                        korean: '${session.currentQuestionIndex + 1}/${session.totalQuestions} 문제',
                        english: 'Question ${session.currentQuestionIndex + 1} of ${session.totalQuestions}',
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (session.hasTimeLimit)
                _buildTimeDisplay(session, isPaused),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(session),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay(TestSession session, bool isPaused) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLowTime = session.timeRemaining != null && session.timeRemaining! < 300;
    
    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    Color textColor;
    
    if (isPaused) {
      backgroundColor = colorScheme.tertiary.withOpacity(0.1);
      borderColor = colorScheme.tertiary;
      iconColor = colorScheme.tertiary;
      textColor = colorScheme.tertiary;
    } else if (isLowTime) {
      backgroundColor = colorScheme.error.withOpacity(0.1);
      borderColor = colorScheme.error;
      iconColor = colorScheme.error;
      textColor = colorScheme.error;
    } else {
      backgroundColor = colorScheme.primary.withOpacity(0.1);
      borderColor = colorScheme.primary;
      iconColor = colorScheme.primary;
      textColor = colorScheme.primary;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaused ? Icons.pause : Icons.timer,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 6),
          Text(
            isPaused
                ? _languageCubit.getLocalizedText(korean: '일시정지', english: 'Paused')
                : session.formattedTimeRemaining,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(TestSession session) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _languageCubit.getLocalizedText(korean: '진행률', english: 'Progress'),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(session.progress * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _progressAnimationController,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: session.progress * _progressAnimationController.value,
              backgroundColor: colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              minHeight: 6,
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuestionContent(TestSession session, TestQuestion question) {
    final savedAnswer = session.getAnswerForQuestion(session.currentQuestionIndex);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionCard(question),
          const SizedBox(height: 24),
          _buildAnswerOptionsGrid(question, savedAnswer),
          const SizedBox(height: 24),
          if (_selectedAnswerIndex != null && !_showingExplanation)
            _buildSubmitButton(savedAnswer),
          if (_showingExplanation && question.explanation != null)
            _buildExplanationCard(question.explanation!),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(TestQuestion question) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (question.questionImageUrl != null && question.questionImageUrl!.isNotEmpty)
            _buildQuestionImage(question.questionImageUrl!),
          
          Padding(
            padding: EdgeInsets.all(question.questionImageUrl != null ? 20 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _languageCubit.getLocalizedText(korean: '문제', english: 'Question'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                if (question.question.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    question.question,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionImage(String imageUrl) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 300),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildImagePlaceholder(300),
          errorWidget: (context, url, error) => _buildImageError('question', 300),
        ),
      ),
    );
  }

  Widget _buildAnswerOptionsGrid(TestQuestion question, savedAnswer) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Text(
            _languageCubit.getLocalizedText(korean: '답안을 선택하세요', english: 'Choose your answer'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        ...question.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          return _buildAnswerOption(index, option, question, savedAnswer);
        }).toList(),
      ],
    );
  }

  Widget _buildAnswerOption(int index, AnswerOption option, TestQuestion question, savedAnswer) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedAnswerIndex == index;
    final isCorrectAnswer = index == question.correctAnswerIndex;
    final wasSelectedAnswer = savedAnswer?.selectedAnswerIndex == index;
    final showResult = _showingExplanation && savedAnswer != null;
    
    Color borderColor = colorScheme.outline;
    Color backgroundColor = colorScheme.surface;
    Color textColor = colorScheme.onSurface;
    Widget? statusIcon;
    
    if (showResult) {
      if (isCorrectAnswer) {
        borderColor = colorScheme.primary;
        backgroundColor = colorScheme.primary.withOpacity(0.1);
        textColor = colorScheme.primary;
        statusIcon = Icon(Icons.check_circle, color: colorScheme.primary, size: 24);
      } else if (wasSelectedAnswer) {
        borderColor = colorScheme.error;
        backgroundColor = colorScheme.error.withOpacity(0.1);
        textColor = colorScheme.error;
        statusIcon = Icon(Icons.cancel, color: colorScheme.error, size: 24);
      }
    } else if (isSelected) {
      borderColor = colorScheme.primary;
      backgroundColor = colorScheme.primary.withOpacity(0.1);
      textColor = colorScheme.primary;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _showingExplanation ? null : () {
            setState(() {
              _selectedAnswerIndex = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2),
              color: backgroundColor,
              boxShadow: isSelected || showResult ? [
                BoxShadow(
                  color: borderColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOptionSelector(index, isSelected || wasSelectedAnswer, borderColor),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOptionContent(index, option, textColor),
                ),
                if (statusIcon != null) ...[
                  const SizedBox(width: 12),
                  statusIcon,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionSelector(int index, bool isSelected, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        color: isSelected ? color : Colors.transparent,
      ),
      child: Center(
        child: isSelected
            ? Icon(Icons.check, color: colorScheme.onPrimary, size: 18)
            : Text(
                String.fromCharCode(65 + index),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  Widget _buildOptionContent(int index, AnswerOption option, Color textColor) {
    if (option.isImage && option.imageUrl != null && option.imageUrl!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: option.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => _buildImagePlaceholder(200),
                errorWidget: (context, url, error) => _buildImageError('answer', 200),
              ),
            ),
          ),
          if (option.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              option.text,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                height: 1.4,
              ),
            ),
          ],
        ],
      );
    } else {
      return Text(
        option.text,
        style: TextStyle(
          fontSize: 16,
          color: textColor,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }

  Widget _buildSubmitButton(savedAnswer) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _answerQuestion,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(savedAnswer != null ? Icons.edit : Icons.send),
            const SizedBox(width: 8),
            Text(
              savedAnswer != null 
                  ? _languageCubit.getLocalizedText(korean: '답변 변경', english: 'Change Answer')
                  : _languageCubit.getLocalizedText(korean: '답변 제출', english: 'Submit Answer'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard(String explanation) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.lightbulb, color: colorScheme.onSecondary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                _languageCubit.getLocalizedText(korean: '해설', english: 'Explanation'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            explanation,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestNavigation(TestSession session) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFirstQuestion = session.currentQuestionIndex == 0;
    final isLastQuestion = session.currentQuestionIndex == session.totalQuestions - 1;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isFirstQuestion)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _previousQuestion(),
                icon: const Icon(Icons.arrow_back),
                label: Text(_languageCubit.getLocalizedText(korean: '이전', english: 'Previous')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          
          if (!isFirstQuestion) const SizedBox(width: 16),
          
          Expanded(
            flex: isFirstQuestion ? 1 : 2,
            child: ElevatedButton.icon(
              onPressed: () => isLastQuestion ? _showFinishConfirmation(session) : _nextQuestion(),
              icon: Icon(isLastQuestion ? Icons.flag : Icons.arrow_forward),
              label: Text(
                isLastQuestion
                    ? _languageCubit.getLocalizedText(korean: '시험 완료', english: 'Finish Test')
                    : _languageCubit.getLocalizedText(korean: '다음', english: 'Next'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastQuestion ? colorScheme.tertiary : colorScheme.primary,
                foregroundColor: isLastQuestion ? colorScheme.onTertiary : colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(double height) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            _languageCubit.getLocalizedText(
              korean: '이미지 로딩 중...',
              english: 'Loading image...',
            ),
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageError(String type, double height) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 40, color: colorScheme.onErrorContainer),
          const SizedBox(height: 8),
          Text(
            _languageCubit.getLocalizedText(
              korean: '$type 이미지 로드 실패',
              english: 'Failed to load $type image',
            ),
            style: TextStyle(
              color: colorScheme.onErrorContainer,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
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

  void _nextQuestion() {
    setState(() {
      _selectedAnswerIndex = null;
      _showingExplanation = false;
    });
    
    _slideAnimationController.reset();
    _sessionCubit.nextQuestion();
    _slideAnimationController.forward();
    _progressAnimationController.forward();
  }

  void _previousQuestion() {
    setState(() {
      _selectedAnswerIndex = null;
      _showingExplanation = false;
    });
    
    _slideAnimationController.reset();
    _sessionCubit.previousQuestion();
    _slideAnimationController.forward();
  }

  void _showFinishConfirmation(TestSession session) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colorScheme.surface,
        title: Text(
          _languageCubit.getLocalizedText(korean: '시험 완료', english: 'Finish Test'),
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          _languageCubit.getLocalizedText(
            korean: '정말로 시험을 완료하시겠습니까?\n답변한 문제: ${session.answeredQuestionsCount}/${session.totalQuestions}',
            english: 'Are you sure you want to finish the test?\nAnswered questions: ${session.answeredQuestionsCount}/${session.totalQuestions}',
          ),
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _languageCubit.getLocalizedText(korean: '취소', english: 'Cancel'),
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sessionCubit.completeTest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.tertiary,
              foregroundColor: colorScheme.onTertiary,
            ),
            child: Text(
              _languageCubit.getLocalizedText(korean: '완료', english: 'Finish'),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colorScheme.surface,
        title: Text(
          _languageCubit.getLocalizedText(korean: '시험 종료', english: 'Exit Test'),
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          _languageCubit.getLocalizedText(
            korean: '시험을 종료하시겠습니까? 진행 상황이 저장되지 않습니다.',
            english: 'Do you want to exit the test? Your progress will not be saved.',
          ),
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _languageCubit.getLocalizedText(korean: '계속하기', english: 'Continue'),
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text(
              _languageCubit.getLocalizedText(korean: '종료', english: 'Exit'),
            ),
          ),
        ],
      ),
    );
  }
}