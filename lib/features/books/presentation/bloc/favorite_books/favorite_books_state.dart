part of 'favorite_books_cubit.dart';

abstract class FavoriteBooksState extends Equatable{}

class FavoriteBooksInitial extends FavoriteBooksState {
  @override
  List<Object?> get props => [];
}

class FavoriteBooksLoading extends FavoriteBooksState {
  @override
  List<Object?> get props => [];
}

class FavoriteBooksLoaded extends FavoriteBooksState {
  final List<BookItem> books;
  final bool hasMore;
  
  FavoriteBooksLoaded(this.books, this.hasMore);
  
  @override
  List<Object?> get props => [books,hasMore];
}

class FavoriteBooksLoadingMore extends FavoriteBooksState {
  final List<BookItem> currentBooks;
  
  FavoriteBooksLoadingMore(this.currentBooks);
  
  @override
  List<Object?> get props => [currentBooks];
}

class FavoriteBooksError extends FavoriteBooksState {
  final String message;
  
  FavoriteBooksError(this.message);
  
  @override
  List<Object?> get props => [message];
}
