part of 'test_session_cubit.dart';

class TestSession {
  final TestItem test;
  final String userId;
  final Map<String, TestAnswer> answers;
  final int currentQuestionIndex;
  final DateTime startTime;
  final DateTime? questionStartTime;
  final DateTime? lastAnswerTime;
  final int? timeRemaining; // in seconds
  final bool isPaused;

  const TestSession({
    required this.test,
    required this.userId,
    required this.answers,
    required this.currentQuestionIndex,
    required this.startTime,
    this.questionStartTime,
    this.lastAnswerTime,
    this.timeRemaining,
    this.isPaused = false,
  });

  TestSession copyWith({
    TestItem? test,
    String? userId,
    Map<String, TestAnswer>? answers,
    int? currentQuestionIndex,
    DateTime? startTime,
    DateTime? questionStartTime,
    DateTime? lastAnswerTime,
    int? timeRemaining,
    bool? isPaused,
  }) {
    return TestSession(
      test: test ?? this.test,
      userId: userId ?? this.userId,
      answers: answers ?? this.answers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      startTime: startTime ?? this.startTime,
      questionStartTime: questionStartTime ?? this.questionStartTime ?? DateTime.now(),
      lastAnswerTime: lastAnswerTime ?? this.lastAnswerTime,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  bool get isCompleted => currentQuestionIndex >= test.questions.length;
  bool get hasTimeLimit => timeRemaining != null;
  int get answeredQuestionsCount => answers.length;
  int get totalQuestions => test.questions.length;
  double get progress => totalQuestions > 0 ? (currentQuestionIndex + 1) / totalQuestions : 0.0;
  
  String get formattedTimeRemaining {
    if (timeRemaining == null) return '';
    final minutes = timeRemaining! ~/ 60;
    final seconds = timeRemaining! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool isQuestionAnswered(int questionIndex) {
    if (questionIndex >= test.questions.length) return false;
    final questionId = test.questions[questionIndex].id;
    return answers.containsKey(questionId);
  }

  TestAnswer? getAnswerForQuestion(int questionIndex) {
    if (questionIndex >= test.questions.length) return null;
    final questionId = test.questions[questionIndex].id;
    return answers[questionId];
  }
}

abstract class TestSessionState extends BaseState {
  const TestSessionState({
    super.isLoading = false,
    super.error,
    super.errorType,
  });

  @override
  TestSessionState copyWithBaseState({
    bool? isLoading,
    String? error,
    FailureType? errorType,
  });
}

class TestSessionInitial extends TestSessionState {
  const TestSessionInitial();

  @override
  TestSessionState copyWithBaseState({
    bool? isLoading,
    String? error,
    FailureType? errorType,
  }) {
    return const TestSessionInitial();
  }

  @override
  List<Object?> get props => [];
}

class TestSessionInProgress extends TestSessionState {
  final TestSession session;

  const TestSessionInProgress(this.session);

  @override
  TestSessionState copyWithBaseState({
    bool? isLoading,
    String? error,
    FailureType? errorType,
  }) {
    return TestSessionInProgress(session);
  }

  @override
  List<Object?> get props => [session];
}

class TestSessionPaused extends TestSessionState {
  final TestSession session;

  const TestSessionPaused(this.session);

  @override
  TestSessionState copyWithBaseState({
    bool? isLoading,
    String? error,
    FailureType? errorType,
  }) {
    return TestSessionPaused(session);
  }

  @override
  List<Object?> get props => [session];
}

class TestSessionSubmitting extends TestSessionState {
  const TestSessionSubmitting() : super(isLoading: true);

  @override
  TestSessionState copyWithBaseState({
    bool? isLoading,
    String? error,
    FailureType? errorType,
  }) {
    return const TestSessionSubmitting();
  }

  @override
  List<Object?> get props => [];
}

class TestSessionCompleted extends TestSessionState {
  final TestResult result;

  const TestSessionCompleted(this.result);

  @override
  TestSessionState copyWithBaseState({
    bool? isLoading,
    String? error,
    FailureType? errorType,
  }) {
    return TestSessionCompleted(result);
  }

  @override
  List<Object?> get props => [result];
}

class TestSessionError extends TestSessionState {
  const TestSessionError(String message, FailureType errorType)
      : super(error: message, errorType: errorType);

  @override
  TestSessionState copyWithBaseState({
    bool? isLoading,
    String? error,
    FailureType? errorType,
  }) {
    return TestSessionError(
      error ?? this.error ?? 'Unknown error',
      errorType ?? this.errorType ?? FailureType.unknown,
    );
  }

  @override
  List<Object?> get props => [error, errorType];
}