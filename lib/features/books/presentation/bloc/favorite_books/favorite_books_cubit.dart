import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/data/base_state.dart';
import 'package:korean_language_app/core/enums/course_category.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/features/books/domain/repositories/favorite_book_repository.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

part 'favorite_books_state.dart';

class FavoriteBooksCubit extends Cubit<FavoriteBooksState> {
  final FavoriteBookRepository repository;
  
  FavoriteBooksCubit(this.repository) : super(const FavoriteBooksState());
  
  Future<void> loadInitialBooks() async {
    if (state.books.isEmpty) {
      emit(state.copyWith(isLoading: true));
    }
    
    final result = await repository.getBooksFromCache();
    
    result.fold(
      onSuccess: (books) async {
        final uniqueBooks = _removeDuplicates(books);
        final hasMoreResult = await repository.hasMoreBooks(
          CourseCategory.favorite, 
          uniqueBooks.length
        );
        
        final hasMore = hasMoreResult.fold(
          onSuccess: (hasMore) => hasMore,
          onFailure: (_, __) => false,
        );
        
        emit(state.copyWith(
          books: uniqueBooks,
          hasMore: hasMore,
          isLoading: false,
          error: null,
          errorType: null,
        ));
      },
      onFailure: (message, type) {
        emit(state.copyWith(
          isLoading: false,
          error: message,
          errorType: type,
        ));
      },
    );
  }
  
  Future<void> hardRefresh() async {
    emit(state.copyWith(isLoading: true));
    
    final result = await repository.hardRefreshBooks(CourseCategory.favorite);
    
    result.fold(
      onSuccess: (books) async {
        final uniqueBooks = _removeDuplicates(books);
        final hasMoreResult = await repository.hasMoreBooks(
          CourseCategory.favorite, 
          uniqueBooks.length
        );
        
        final hasMore = hasMoreResult.fold(
          onSuccess: (hasMore) => hasMore,
          onFailure: (_, __) => false,
        );
        
        emit(state.copyWith(
          books: uniqueBooks,
          hasMore: hasMore,
          isLoading: false,
          error: null,
          errorType: null,
        ));
      },
      onFailure: (message, type) {
        emit(state.copyWith(
          isLoading: false,
          error: message,
          errorType: type,
        ));
      },
    );
  }
  
  Future<void> searchBooks(String query) async {
    emit(state.copyWith(isLoading: true));
    
    final result = await repository.searchBooks(CourseCategory.favorite, query);
    
    result.fold(
      onSuccess: (books) {
        emit(state.copyWith(
          books: _removeDuplicates(books),
          hasMore: false,
          isLoading: false,
          error: null,
          errorType: null,
        ));
      },
      onFailure: (message, type) {
        emit(state.copyWith(
          isLoading: false,
          error: message,
          errorType: type,
        ));
      },
    );
  }

  Future<void> toggleFavorite(BookItem bookItem) async {
    final currentBooks = state.books;
    final bool isAlreadyFavorite = currentBooks.any((book) => book.id == bookItem.id);
    
    final result = isAlreadyFavorite
        ? await repository.removeBookFromFavorite(bookItem)
        : await repository.addFavoritedBook(bookItem);
        
    result.fold(
      onSuccess: (updatedBooks) async {
        final hasMoreResult = await repository.hasMoreBooks(
          CourseCategory.favorite, 
          updatedBooks.length
        );
        
        final hasMore = hasMoreResult.fold(
          onSuccess: (hasMore) => hasMore,
          onFailure: (_, __) => false,
        );
        
        emit(state.copyWith(
          books: _removeDuplicates(updatedBooks),
          hasMore: hasMore,
          error: null,
          errorType: null,
        ));
      },
      onFailure: (message, type) {
        emit(state.copyWith(
          error: message,
          errorType: type,
        ));
        loadInitialBooks(); // Recover from error by reloading
      },
    );
  }
  
  List<BookItem> _removeDuplicates(List<BookItem> books) {
    final uniqueIds = <String>{};
    final uniqueBooks = <BookItem>[];
    
    for (final book in books) {
      if (uniqueIds.add(book.id)) {
        uniqueBooks.add(book);
      }
    }
    
    return uniqueBooks;
  }
}