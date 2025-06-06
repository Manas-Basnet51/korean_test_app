part of 'test_upload_cubit.dart';

enum TestUploadOperationType { 
  createTest,
  updateTest,
  deleteTest
}

enum TestUploadOperationStatus { 
  none, 
  inProgress, 
  completed, 
  failed 
}

class TestUploadOperation {
  final TestUploadOperationType? type;
  final TestUploadOperationStatus status;
  final String? message;
  final String? testId;
  
  const TestUploadOperation({
    this.type,
    required this.status,
    this.message,
    this.testId,
  });
  
  bool get isInProgress => status == TestUploadOperationStatus.inProgress;
  bool get isCompleted => status == TestUploadOperationStatus.completed;
  bool get isFailed => status == TestUploadOperationStatus.failed;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestUploadOperation &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          status == other.status &&
          message == other.message &&
          testId == other.testId;
          
  @override
  int get hashCode => type.hashCode ^ status.hashCode ^ (message?.hashCode ?? 0) ^ (testId?.hashCode ?? 0);
}

class TestUploadState extends BaseState {
  final TestUploadOperation currentOperation;
  final TestItem? createdTest;

  const TestUploadState({
    super.isLoading = false,
    super.error,
    super.errorType,
    required this.currentOperation,
    this.createdTest,
  });

  @override
  TestUploadState copyWithBaseState({
    bool? isLoading,
    String? error,
    FailureType? errorType,
  }) {
    return TestUploadState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      errorType: errorType,
      currentOperation: currentOperation,
      createdTest: createdTest,
    );
  }

  TestUploadState copyWith({
    bool? isLoading,
    String? error,
    FailureType? errorType,
    TestUploadOperation? currentOperation,
    TestItem? createdTest,
  }) {
    return TestUploadState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      errorType: errorType,
      currentOperation: currentOperation ?? this.currentOperation,
      createdTest: createdTest ?? this.createdTest,
    );
  }

  TestUploadState copyWithOperation(TestUploadOperation operation) {
    return TestUploadState(
      isLoading: isLoading,
      error: error,
      errorType: errorType,
      currentOperation: operation,
      createdTest: createdTest,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        currentOperation,
        createdTest,
      ];
}

class TestUploadInitial extends TestUploadState {
  const TestUploadInitial() : super(
    currentOperation: const TestUploadOperation(status: TestUploadOperationStatus.none),
  );
}