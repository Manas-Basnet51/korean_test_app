part of 'korean_books_cubit.dart';

enum KoreanBooksOperationType { 
  loadBooks, 
  loadMoreBooks, 
  searchBooks, 
  loadPdf, 
  refreshBooks 
}

enum KoreanBooksOperationStatus { 
  none, 
  inProgress, 
  completed, 
  failed 
}

class KoreanBooksOperation {
  final KoreanBooksOperationType? type;
  final KoreanBooksOperationStatus status;
  final String? message;
  final String? bookId;
  
  const KoreanBooksOperation({
    this.type,
    required this.status,
    this.message,
    this.bookId,
  });
  
  bool get isInProgress => status == KoreanBooksOperationStatus.inProgress;
  bool get isCompleted => status == KoreanBooksOperationStatus.completed;
  bool get isFailed => status == KoreanBooksOperationStatus.failed;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KoreanBooksOperation &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          status == other.status &&
          message == other.message &&
          bookId == other.bookId;
          
  @override
  int get hashCode => type.hashCode ^ status.hashCode ^ (message?.hashCode ?? 0) ^ (bookId?.hashCode ?? 0);
}

class KoreanBooksState extends BaseState {
  final List<BookItem> books;
  final bool hasMore;
  final KoreanBooksOperation currentOperation;
  final File? loadedPdfFile;
  final String? loadedPdfBookId;

  const KoreanBooksState({
    super.isLoading = false,
    super.error,
    super.errorType,
    this.books = const [],
    this.hasMore = false,
    required this.currentOperation,
    this.loadedPdfFile,
    this.loadedPdfBookId,
  });

  @override
  KoreanBooksState copyWithBaseState({
    bool? isLoading,
    String? error,
    FailureType? errorType,
  }) {
    return KoreanBooksState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      errorType: errorType,
      books: books,
      hasMore: hasMore,
      currentOperation: currentOperation,
      loadedPdfFile: loadedPdfFile,
      loadedPdfBookId: loadedPdfBookId,
    );
  }

  KoreanBooksState copyWith({
    bool? isLoading,
    String? error,
    FailureType? errorType,
    List<BookItem>? books,
    bool? hasMore,
    KoreanBooksOperation? currentOperation,
    File? loadedPdfFile,
    String? loadedPdfBookId,
  }) {
    return KoreanBooksState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      errorType: errorType,
      books: books ?? this.books,
      hasMore: hasMore ?? this.hasMore,
      currentOperation: currentOperation ?? this.currentOperation,
      loadedPdfFile: loadedPdfFile ?? this.loadedPdfFile,
      loadedPdfBookId: loadedPdfBookId ?? this.loadedPdfBookId,
    );
  }

  KoreanBooksState copyWithOperation(KoreanBooksOperation operation) {
    return KoreanBooksState(
      isLoading: isLoading,
      error: error,
      errorType: errorType,
      books: books,
      hasMore: hasMore,
      currentOperation: operation,
      loadedPdfFile: loadedPdfFile,
      loadedPdfBookId: loadedPdfBookId,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        books,
        hasMore,
        currentOperation,
        loadedPdfFile?.path,
        loadedPdfBookId,
      ];
}

class KoreanBooksInitial extends KoreanBooksState {
  const KoreanBooksInitial() : super(
    currentOperation: const KoreanBooksOperation(status: KoreanBooksOperationStatus.none),
  );
}