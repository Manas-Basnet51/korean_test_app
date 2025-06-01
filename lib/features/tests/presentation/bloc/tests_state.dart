part of 'tests_cubit.dart';

enum TestsOperationType { 
  loadTests, 
  loadMoreTests, 
  searchTests, 
  refreshTests,
  loadTestById,
  createTest,
  updateTest,
  deleteTest
}

enum TestsOperationStatus { 
  none, 
  inProgress, 
  completed, 
  failed 
}

class TestsOperation {
  final TestsOperationType? type;
  final TestsOperationStatus status;
  final String? message;
  final String? testId;
  
  const TestsOperation({
    this.type,
    required this.status,
    this.message,
    this.testId,
  });
  
  bool get isInProgress => status == TestsOperationStatus.inProgress;
  bool get isCompleted => status == TestsOperationStatus.completed;
  bool get isFailed => status == TestsOperationStatus.failed;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestsOperation &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          status == other.status &&
          message == other.message &&
          testId == other.testId;
          
  @override
  int get hashCode => type.hashCode ^ status.hashCode ^ (message?.hashCode ?? 0) ^ (testId?.hashCode ?? 0);
}

class TestsState extends BaseState {
  final List<TestItem> tests;
  final bool hasMore;
  final TestsOperation currentOperation;
  final TestItem? selectedTest;

  const TestsState({
    super.isLoading = false,
    super.error,
    super.errorType,
    this.tests = const [],
    this.hasMore = false,
    required this.currentOperation,
    this.selectedTest,
  });

  @override
  TestsState copyWithBaseState({
    bool? isLoading,
    String? error,
    FailureType? errorType,
  }) {
    return TestsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      errorType: errorType,
      tests: tests,
      hasMore: hasMore,
      currentOperation: currentOperation,
      selectedTest: selectedTest,
    );
  }

  TestsState copyWith({
    bool? isLoading,
    String? error,
    FailureType? errorType,
    List<TestItem>? tests,
    bool? hasMore,
    TestsOperation? currentOperation,
    TestItem? selectedTest,
  }) {
    return TestsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      errorType: errorType,
      tests: tests ?? this.tests,
      hasMore: hasMore ?? this.hasMore,
      currentOperation: currentOperation ?? this.currentOperation,
      selectedTest: selectedTest ?? this.selectedTest,
    );
  }

  TestsState copyWithOperation(TestsOperation operation) {
    return TestsState(
      isLoading: isLoading,
      error: error,
      errorType: errorType,
      tests: tests,
      hasMore: hasMore,
      currentOperation: operation,
      selectedTest: selectedTest,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        tests,
        hasMore,
        currentOperation,
        selectedTest,
      ];
}

class TestsInitial extends TestsState {
  const TestsInitial() : super(
    currentOperation: const TestsOperation(status: TestsOperationStatus.none),
  );
}