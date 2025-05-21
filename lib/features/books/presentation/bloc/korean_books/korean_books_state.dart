part of 'korean_books_cubit.dart';

class KoreanBooksState extends BaseState {
  final List<BookItem> books;
  final bool hasMore;
  final File? loadedPdfFile;
  final String? pdfLoadingBookId;
  final bool isLoadingMore;

  const KoreanBooksState({
    super.isLoading = false,
    super.error,
    super.errorType,
    this.books = const [],
    this.hasMore = false,
    this.loadedPdfFile,
    this.pdfLoadingBookId,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    books,
    hasMore,
    loadedPdfFile,
    pdfLoadingBookId,
    isLoadingMore,
  ];

  @override
  KoreanBooksState copyWithBaseState({
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

  KoreanBooksState copyWith({
    bool? isLoading,
    String? error,
    FailureType? errorType,
    List<BookItem>? books,
    bool? hasMore,
    File? loadedPdfFile,
    String? pdfLoadingBookId,
    bool? isLoadingMore,
  }) {
    return KoreanBooksState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      errorType: errorType,
      books: books ?? this.books,
      hasMore: hasMore ?? this.hasMore,
      loadedPdfFile: loadedPdfFile ?? this.loadedPdfFile,
      pdfLoadingBookId: pdfLoadingBookId ?? this.pdfLoadingBookId,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}