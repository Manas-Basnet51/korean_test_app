part of 'favorite_books_cubit.dart';

class FavoriteBooksState extends BaseState {
  final List<BookItem> books;
  final bool hasMore;
  final bool isLoadingMore;

  const FavoriteBooksState({
    super.isLoading = false,
    super.error,
    super.errorType,
    this.books = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    books,
    hasMore,
    isLoadingMore,
  ];

  @override
  FavoriteBooksState copyWithBaseState({
    bool? isLoading,
    String? error,
    FailureType? errorType,
  }) {
    return copyWith(
      isLoading: isLoading,
      error: error,
      errorType: errorType,
    );
  }

  FavoriteBooksState copyWith({
    bool? isLoading,
    String? error,
    FailureType? errorType,
    List<BookItem>? books,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return FavoriteBooksState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      errorType: errorType,
      books: books ?? this.books,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}