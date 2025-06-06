part of 'test_results_cubit.dart';

enum TestResultsOperationType { 
  saveResult,
  loadResults,
  loadTestResults,
  loadLatestResult
}

enum TestResultsOperationStatus { 
  none, 
  inProgress, 
  completed, 
  failed 
}

class TestResultsOperation {
  final TestResultsOperationType? type;
  final TestResultsOperationStatus status;
  final String? message;
  final String? testId;
  
  const TestResultsOperation({
    this.type,
    required this.status,
    this.message,
    this.testId,
  });
  
  bool get isInProgress => status == TestResultsOperationStatus.inProgress;
  bool get isCompleted => status == TestResultsOperationStatus.completed;
  bool get isFailed => status == TestResultsOperationStatus.failed;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestResultsOperation &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          status == other.status &&
          message == other.message &&
          testId == other.testId;
          
  @override
  int get hashCode => type.hashCode ^ status.hashCode ^ (message?.hashCode ?? 0) ^ (testId?.hashCode ?? 0);
}

class TestResultsState extends BaseState {
  final TestResultsOperation currentOperation;
  final List<TestResult> results;
  final List<TestResult> testResults;
  final TestResult? latestResult;

  const TestResultsState({
    super.isLoading = false,
    super.error,
    super.errorType,
    required this.currentOperation,
    this.results = const [],
    this.testResults = const [],
    this.latestResult,
  });

  @override
  TestResultsState copyWithBaseState({
    bool? isLoading,
    String? error,
    FailureType? errorType,
  }) {
    return TestResultsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      errorType: errorType,
      currentOperation: currentOperation,
      results: results,
      testResults: testResults,
      latestResult: latestResult,
    );
  }

  TestResultsState copyWith({
    bool? isLoading,
    String? error,
    FailureType? errorType,
    TestResultsOperation? currentOperation,
    List<TestResult>? results,
    List<TestResult>? testResults,
    TestResult? latestResult,
  }) {
    return TestResultsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      errorType: errorType,
      currentOperation: currentOperation ?? this.currentOperation,
      results: results ?? this.results,
      testResults: testResults ?? this.testResults,
      latestResult: latestResult ?? this.latestResult,
    );
  }

  TestResultsState copyWithOperation(TestResultsOperation operation) {
    return TestResultsState(
      isLoading: isLoading,
      error: error,
      errorType: errorType,
      currentOperation: operation,
      results: results,
      testResults: testResults,
      latestResult: latestResult,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        currentOperation,
        results,
        testResults,
        latestResult,
      ];
}

class TestResultsInitial extends TestResultsState {
  const TestResultsInitial() : super(
    currentOperation: const TestResultsOperation(status: TestResultsOperationStatus.none),
  );
}