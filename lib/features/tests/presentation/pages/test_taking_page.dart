import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isLandscape = false;
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
    // Reset orientation when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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

  void _toggleOrientation() {
    setState(() {
      _isLandscape = !_isLandscape;
    });

    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  void _showFullScreenImage(String imageUrl, String type) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _languageCubit.getLocalizedText(
                            korean: '이미지를 불러올 수 없습니다',
                            english: 'Cannot load image',
                          ),
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _languageCubit.getLocalizedText(
                    korean: '핀치하여 확대/축소, 드래그하여 이동',
                    english: 'Pinch to zoom, drag to move',
                  ),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              _languageCubit.getLocalizedText(
                korean: '시험을 준비하고 있습니다...',
                english: 'Preparing your test...',
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
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
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
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
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: Text(
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
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTestHeader(session, isPaused),
            Expanded(
              child: AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - _slideAnimation.value)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _showExitConfirmation(),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  foregroundColor: colorScheme.onSurfaceVariant,
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.test.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _languageCubit.getLocalizedText(
                        korean: '${session.currentQuestionIndex + 1}/${session.totalQuestions}',
                        english: '${session.currentQuestionIndex + 1} of ${session.totalQuestions}',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _buildOrientationToggle(),
              const SizedBox(width: 8),
              if (session.hasTimeLimit)
                _buildTimeDisplay(session, isPaused),
            ],
          ),
          const SizedBox(height: 12),
          _buildProgressBar(session),
        ],
      ),
    );
  }

  Widget _buildOrientationToggle() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ToggleButtons(
      isSelected: [!_isLandscape, _isLandscape],
      onPressed: (index) => _toggleOrientation(),
      borderRadius: BorderRadius.circular(6),
      selectedColor: colorScheme.onPrimary,
      fillColor: colorScheme.primary,
      color: colorScheme.onSurfaceVariant,
      constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
      children: [
        Tooltip(
          message: _languageCubit.getLocalizedText(korean: '세로 모드', english: 'Portrait'),
          child: Icon(Icons.stay_current_portrait, size: 16),
        ),
        Tooltip(
          message: _languageCubit.getLocalizedText(korean: '가로 모드', english: 'Landscape'),
          child: Icon(Icons.stay_current_landscape, size: 16),
        ),
      ],
    );
  }

  Widget _buildTimeDisplay(TestSession session, bool isPaused) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLowTime = session.timeRemaining != null && session.timeRemaining! < 300;
    
    Color backgroundColor;
    Color textColor;
    IconData icon;
    
    if (isPaused) {
      backgroundColor = colorScheme.tertiary.withOpacity(0.1);
      textColor = colorScheme.tertiary;
      icon = Icons.pause;
    } else if (isLowTime) {
      backgroundColor = colorScheme.errorContainer.withOpacity(0.3);
      textColor = colorScheme.error;
      icon = Icons.timer;
    } else {
      backgroundColor = colorScheme.primaryContainer.withOpacity(0.3);
      textColor = colorScheme.primary;
      icon = Icons.timer;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            isPaused
                ? _languageCubit.getLocalizedText(korean: '일시정지', english: 'Paused')
                : session.formattedTimeRemaining,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
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
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${(session.progress * 100).round()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _progressAnimationController,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: session.progress * _progressAnimationController.value,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuestionContent(TestSession session, TestQuestion question) {
    final savedAnswer = session.getAnswerForQuestion(session.currentQuestionIndex);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionCard(question),
          const SizedBox(height: 20),
          _buildAnswerOptions(question, savedAnswer),
          const SizedBox(height: 20),
          if (_selectedAnswerIndex != null && !_showingExplanation)
            _buildSubmitButton(savedAnswer),
          if (_showingExplanation && question.explanation != null)
            _buildExplanationCard(question.explanation!),
          const SizedBox(height: 20),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (question.questionImageUrl != null && question.questionImageUrl!.isNotEmpty)
            _buildQuestionImage(question.questionImageUrl!),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _languageCubit.getLocalizedText(korean: '문제', english: 'Question'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (question.question.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    question.question,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.4,
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
    return GestureDetector(
      onDoubleTap: () => _showFullScreenImage(imageUrl, 'question'),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 250),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildImagePlaceholder(250),
            errorWidget: (context, url, error) => _buildImageError(250),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerOptions(TestQuestion question, savedAnswer) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _languageCubit.getLocalizedText(korean: '답안 선택', english: 'Choose Answer'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
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
    
    Color borderColor = colorScheme.outlineVariant;
    Color backgroundColor = colorScheme.surface;
    Widget? statusIcon;
    
    if (showResult) {
      if (isCorrectAnswer) {
        borderColor = Colors.green;
        backgroundColor = Colors.green.withOpacity(0.1);
        statusIcon = Icon(Icons.check_circle, color: Colors.green, size: 20);
      } else if (wasSelectedAnswer) {
        borderColor = Colors.red;
        backgroundColor = Colors.red.withOpacity(0.1);
        statusIcon = Icon(Icons.cancel, color: Colors.red, size: 20);
      }
    } else if (isSelected) {
      borderColor = colorScheme.primary;
      backgroundColor = colorScheme.primaryContainer.withOpacity(0.3);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _showingExplanation ? null : () {
            setState(() {
              _selectedAnswerIndex = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              color: backgroundColor,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOptionSelector(index, isSelected || wasSelectedAnswer, borderColor),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOptionContent(index, option),
                ),
                if (statusIcon != null) ...[
                  const SizedBox(width: 8),
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
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        color: isSelected ? color : Colors.transparent,
      ),
      child: Center(
        child: isSelected
            ? Icon(Icons.check, color: colorScheme.onPrimary, size: 14)
            : Text(
                String.fromCharCode(65 + index),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
      ),
    );
  }

  Widget _buildOptionContent(int index, AnswerOption option) {
    final theme = Theme.of(context);
    
    if (option.isImage && option.imageUrl != null && option.imageUrl!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onDoubleTap: () => _showFullScreenImage(option.imageUrl!, 'answer'),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: option.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => _buildImagePlaceholder(150),
                  errorWidget: (context, url, error) => _buildImageError(150),
                ),
              ),
            ),
          ),
          if (option.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              option.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.3,
              ),
            ),
          ],
        ],
      );
    } else {
      return Text(
        option.text,
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.3,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }

  Widget _buildSubmitButton(savedAnswer) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _answerQuestion,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          savedAnswer != null 
              ? _languageCubit.getLocalizedText(korean: '답변 변경', english: 'Change Answer')
              : _languageCubit.getLocalizedText(korean: '답변 제출', english: 'Submit Answer'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildExplanationCard(String explanation) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: colorScheme.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                _languageCubit.getLocalizedText(korean: '해설', english: 'Explanation'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            explanation,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          if (!isFirstQuestion)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _previousQuestion(),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(_languageCubit.getLocalizedText(korean: '이전', english: 'Previous')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          
          if (!isFirstQuestion) const SizedBox(width: 12),
          
          Expanded(
            flex: isFirstQuestion ? 1 : 1,
            child: ElevatedButton.icon(
              onPressed: () => isLastQuestion ? _showFinishConfirmation(session) : _nextQuestion(),
              icon: Icon(isLastQuestion ? Icons.flag_outlined : Icons.arrow_forward, size: 18),
              label: Text(
                isLastQuestion
                    ? _languageCubit.getLocalizedText(korean: '완료', english: 'Finish')
                    : _languageCubit.getLocalizedText(korean: '다음', english: 'Next'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastQuestion ? Colors.green : colorScheme.primary,
                foregroundColor: isLastQuestion ? Colors.white : colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            _languageCubit.getLocalizedText(
              korean: '로딩 중...',
              english: 'Loading...',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageError(double height) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 32, color: colorScheme.error),
          const SizedBox(height: 8),
          Text(
            _languageCubit.getLocalizedText(
              korean: '이미지 로드 실패',
              english: 'Failed to load image',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          _languageCubit.getLocalizedText(korean: '시험 완료', english: 'Finish Test'),
        ),
        content: Text(
          _languageCubit.getLocalizedText(
            korean: '정말로 시험을 완료하시겠습니까?\n답변: ${session.answeredQuestionsCount}/${session.totalQuestions}',
            english: 'Are you sure you want to finish?\nAnswered: ${session.answeredQuestionsCount}/${session.totalQuestions}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _languageCubit.getLocalizedText(korean: '취소', english: 'Cancel'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sessionCubit.completeTest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          _languageCubit.getLocalizedText(korean: '시험 종료', english: 'Exit Test'),
        ),
        content: Text(
          _languageCubit.getLocalizedText(
            korean: '시험을 종료하시겠습니까? 진행 상황이 저장되지 않습니다.',
            english: 'Exit the test? Your progress will not be saved.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _languageCubit.getLocalizedText(korean: '계속하기', english: 'Continue'),
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