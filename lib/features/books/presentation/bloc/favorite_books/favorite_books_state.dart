part of 'favorite_books_cubit.dart';

enum FavoriteBooksOperationType { 
  loadBooks, 
  searchBooks, 
  toggleFavorite, 
  refreshBooks 
}

enum FavoriteBooksOperationStatus { 
  none, 
  inProgress, 
  completed, 
  failed 
}

class FavoriteBooksOperation {
  final FavoriteBooksOperationType? type;
  final FavoriteBooksOperationStatus status;
  final String? message;
  
  const FavoriteBooksOperation({
    this.type,
    required this.status,
    this.message,
  });
  
  bool get isInProgress => status == FavoriteBooksOperationStatus.inProgress;
  bool get isCompleted => status == FavoriteBooksOperationStatus.completed;
  bool get isFailed => status == FavoriteBooksOperationStatus.failed;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteBooksOperation &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          status == other.status &&
          message == other.message;
          
  @override
  int get hashCode => type.hashCode ^ status.hashCode ^ (message?.hashCode ?? 0);
}

class FavoriteBooksState extends BaseState {
  final List<BookItem> books;
  final bool hasMore;
  final FavoriteBooksOperation currentOperation;

  const FavoriteBooksState({
    super.isLoading = false,
    super.error,
    super.errorType,
    this.books = const [],
    this.hasMore = false,
    required this.currentOperation,
  });

  @override
  FavoriteBooksState copyWithBaseState({
    bool? isLoading,
    String? error,
    FailureType? errorType,
  }) {
    return FavoriteBooksState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      errorType: errorType,
      books: books,
      hasMore: hasMore,
      currentOperation: currentOperation,
    );
  }

  FavoriteBooksState copyWith({
    bool? isLoading,
    String? error,
    FailureType? errorType,
    List<BookItem>? books,
    bool? hasMore,
    FavoriteBooksOperation? currentOperation,
  }) {
    return FavoriteBooksState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      errorType: errorType,
      books: books ?? this.books,
      hasMore: hasMore ?? this.hasMore,
      currentOperation: currentOperation ?? this.currentOperation,
    );
  }

  FavoriteBooksState copyWithOperation(FavoriteBooksOperation operation) {
    return FavoriteBooksState(
      isLoading: isLoading,
      error: error,
      errorType: errorType,
      books: books,
      hasMore: hasMore,
      currentOperation: operation,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        books,
        hasMore,
        currentOperation,
      ];
}

class FavoriteBooksInitial extends FavoriteBooksState {
  const FavoriteBooksInitial() : super(
    currentOperation: const FavoriteBooksOperation(status: FavoriteBooksOperationStatus.none),
  );
}