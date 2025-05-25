part of 'korean_books_cubit.dart';

abstract class KoreanBooksState extends Equatable {
  const KoreanBooksState();
  
  @override
  List<Object?> get props => [];
}
class KoreanBooksInitial extends KoreanBooksState {}

class KoreanBooksLoading extends KoreanBooksState {}

class KoreanBooksLoaded extends KoreanBooksState {
  final List<BookItem> books;
  final bool hasMore;
  
  const KoreanBooksLoaded(this.books, this.hasMore);
  
  @override
  List<Object?> get props => [books, hasMore];
}
class KoreanBooksLoadingMore extends KoreanBooksState {
  final List<BookItem> currentBooks;
  
  const KoreanBooksLoadingMore(this.currentBooks);
  
  @override
  List<Object?> get props => [currentBooks];
}
class KoreanBooksError extends KoreanBooksState {
  final String message;
  
  const KoreanBooksError(this.message);
  
  @override
  List<Object?> get props => [message];
}
class KoreanBookPdfLoading extends KoreanBooksState {
  final String bookId;
  final List<BookItem> books;
  final bool hasMore;
  
  const KoreanBookPdfLoading(this.bookId, this.books, this.hasMore);
  
  @override
  List<Object?> get props => [bookId, books, hasMore];
}

class KoreanBookPdfLoaded extends KoreanBooksState {
  final String bookId;
  final File pdfFile;
  final List<BookItem> books;
  final bool hasMore;
  
  const KoreanBookPdfLoaded(this.bookId, this.pdfFile, this.books, this.hasMore);
  
  @override
  List<Object?> get props => [bookId, pdfFile.path, books, hasMore];
}

class KoreanBookPdfError extends KoreanBooksState {
  final String bookId;
  final String message;
  final List<BookItem> books;
  final bool hasMore;
  
  const KoreanBookPdfError(this.bookId, this.message, this.books, this.hasMore);
  
  @override
  List<Object?> get props => [bookId, message, books, hasMore];
}