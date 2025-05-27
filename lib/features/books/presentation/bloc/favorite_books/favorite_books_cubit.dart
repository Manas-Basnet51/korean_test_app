import 'dart:developer' as dev;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/data/base_state.dart';
import 'package:korean_language_app/core/enums/course_category.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/features/books/domain/repositories/favorite_book_repository.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

part 'favorite_books_state.dart';

class FavoriteBooksCubit extends Cubit<FavoriteBooksState> {
  final FavoriteBookRepository repository;
  
  // Performance monitoring
  final Stopwatch _operationStopwatch = Stopwatch();
  
  FavoriteBooksCubit(this.repository) : super(const FavoriteBooksInitial());
  
  Future<void> loadInitialBooks() async {
    if (state.currentOperation.isInProgress) {
      dev.log('Favorite books load operation already in progress, skipping...');
      return;
    }
    
    _operationStopwatch.reset();
    _operationStopwatch.start();
    
    try {
      emit(state.copyWith(
        isLoading: true,
        error: null,
        errorType: null,
        currentOperation: const FavoriteBooksOperation(
          type: FavoriteBooksOperationType.loadBooks,
          status: FavoriteBooksOperationStatus.inProgress,
        ),
      ));
      
      final result = await repository.getBooksFromCache();
      
      result.fold(
        onSuccess: (books) async {
          final uniqueBooks = _removeDuplicates(books);
          
          final hasMoreResult = await repository.hasMoreBooks(CourseCategory.favorite, uniqueBooks.length);
          
          _operationStopwatch.stop();
          dev.log('loadFavoriteBooks completed in ${_operationStopwatch.elapsedMilliseconds}ms with ${uniqueBooks.length} books');
          
          emit(FavoriteBooksState(
            books: uniqueBooks,
            hasMore: hasMoreResult.fold(
              onSuccess: (hasMore) => hasMore,
              onFailure: (_, __) => false,
            ),
            currentOperation: const FavoriteBooksOperation(
              type: FavoriteBooksOperationType.loadBooks,
              status: FavoriteBooksOperationStatus.completed,
            ),
          ));
          
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          _operationStopwatch.stop();
          dev.log('loadFavoriteBooks failed after ${_operationStopwatch.elapsedMilliseconds}ms: $message');
          
          emit(state.copyWithBaseState(
            error: message,
            errorType: type,
            isLoading: false,
          ).copyWithOperation(const FavoriteBooksOperation(
            type: FavoriteBooksOperationType.loadBooks,
            status: FavoriteBooksOperationStatus.failed,
          )));
          _clearOperationAfterDelay();
        },
      );
    } catch (e) {
      _operationStopwatch.stop();
      dev.log('Error loading favorite books after ${_operationStopwatch.elapsedMilliseconds}ms: $e');
      _handleError('Failed to load favorite books: $e', FavoriteBooksOperationType.loadBooks);
    }
  }
  
  Future<void> hardRefresh() async {
    if (state.currentOperation.isInProgress) {
      dev.log('Favorite books refresh operation already in progress, skipping...');
      return;
    }
    
    _operationStopwatch.reset();
    _operationStopwatch.start();
    
    try {
      emit(state.copyWith(
        isLoading: true,
        error: null,
        errorType: null,
        currentOperation: const FavoriteBooksOperation(
          type: FavoriteBooksOperationType.refreshBooks,
          status: FavoriteBooksOperationStatus.inProgress,
        ),
      ));
      
      final result = await repository.getBooksFromCache();
      
      result.fold(
        onSuccess: (books) async {
          final uniqueBooks = _removeDuplicates(books);
          
          final hasMoreResult = await repository.hasMoreBooks(CourseCategory.favorite, uniqueBooks.length);
          
          _operationStopwatch.stop();
          dev.log('refreshFavoriteBooks completed in ${_operationStopwatch.elapsedMilliseconds}ms with ${uniqueBooks.length} books');
          
          emit(FavoriteBooksState(
            books: uniqueBooks,
            hasMore: hasMoreResult.fold(
              onSuccess: (hasMore) => hasMore,
              onFailure: (_, __) => false,
            ),
            currentOperation: const FavoriteBooksOperation(
              type: FavoriteBooksOperationType.refreshBooks,
              status: FavoriteBooksOperationStatus.completed,
            ),
          ));
          
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          _operationStopwatch.stop();
          dev.log('refreshFavoriteBooks failed after ${_operationStopwatch.elapsedMilliseconds}ms: $message');
          
          emit(state.copyWithBaseState(
            error: message,
            errorType: type,
            isLoading: false,
          ).copyWithOperation(const FavoriteBooksOperation(
            type: FavoriteBooksOperationType.refreshBooks,
            status: FavoriteBooksOperationStatus.failed,
          )));
          _clearOperationAfterDelay();
        },
      );
    } catch (e) {
      _operationStopwatch.stop();
      dev.log('Error refreshing favorite books after ${_operationStopwatch.elapsedMilliseconds}ms: $e');
      _handleError('Failed to refresh favorite books: $e', FavoriteBooksOperationType.refreshBooks);
    }
  }
  
  Future<void> searchBooks(String query) async {
    if (state.currentOperation.isInProgress) {
      dev.log('Favorite books search operation already in progress, skipping...');
      return;
    }
    
    _operationStopwatch.reset();
    _operationStopwatch.start();
    
    try {
      emit(state.copyWith(
        isLoading: true,
        currentOperation: const FavoriteBooksOperation(
          type: FavoriteBooksOperationType.searchBooks,
          status: FavoriteBooksOperationStatus.inProgress,
        ),
      ));
      
      final result = await repository.searchBooks(CourseCategory.favorite, query);
      
      result.fold(
        onSuccess: (searchResults) {
          final uniqueSearchResults = _removeDuplicates(searchResults);
          
          _operationStopwatch.stop();
          dev.log('searchFavoriteBooks completed in ${_operationStopwatch.elapsedMilliseconds}ms with ${uniqueSearchResults.length} results for query: "$query"');
          
          emit(state.copyWith(
            books: uniqueSearchResults,
            hasMore: false, // No pagination for search results
            isLoading: false,
            error: null,
            errorType: null,
            currentOperation: const FavoriteBooksOperation(
              type: FavoriteBooksOperationType.searchBooks,
              status: FavoriteBooksOperationStatus.completed,
            ),
          ));
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          _operationStopwatch.stop();
          dev.log('searchFavoriteBooks failed after ${_operationStopwatch.elapsedMilliseconds}ms: $message');
          
          emit(state.copyWithBaseState(
            error: message,
            errorType: type,
            isLoading: false,
          ).copyWithOperation(const FavoriteBooksOperation(
            type: FavoriteBooksOperationType.searchBooks,
            status: FavoriteBooksOperationStatus.failed,
          ))); 
          _clearOperationAfterDelay();
        },
      );
    } catch (e) {
      _operationStopwatch.stop();
      dev.log('Error searching favorite books after ${_operationStopwatch.elapsedMilliseconds}ms: $e');
      _handleError('Failed to search favorite books: $e', FavoriteBooksOperationType.searchBooks);
    }
  }

  Future<void> toggleFavorite(BookItem bookItem) async {
    if (state.currentOperation.type == FavoriteBooksOperationType.toggleFavorite && 
        state.currentOperation.isInProgress) {
      dev.log('Toggle favorite operation already in progress for book: ${bookItem.id}');
      return;
    }
    
    _operationStopwatch.reset();
    _operationStopwatch.start();
    
    try {
      emit(state.copyWith(
        currentOperation: const FavoriteBooksOperation(
          type: FavoriteBooksOperationType.toggleFavorite,
          status: FavoriteBooksOperationStatus.inProgress,
        ),
      ));
      
      final currentBooks = state.books;
      final isAlreadyFavorite = currentBooks.any((book) => book.id == bookItem.id);
      
      final result = isAlreadyFavorite
          ? await repository.removeBookFromFavorite(bookItem)
          : await repository.addFavoritedBook(bookItem);
      
      result.fold(
        onSuccess: (updatedBooks) async {
          final hasMoreResult = await repository.hasMoreBooks(CourseCategory.favorite, updatedBooks.length);
          
          _operationStopwatch.stop();
          dev.log('toggleFavorite completed in ${_operationStopwatch.elapsedMilliseconds}ms for book: ${bookItem.title} (${isAlreadyFavorite ? 'removed' : 'added'})');
          
          emit(state.copyWith(
            books: updatedBooks,
            hasMore: hasMoreResult.fold(
              onSuccess: (hasMore) => hasMore,
              onFailure: (_, __) => false,
            ),
            currentOperation: const FavoriteBooksOperation(
              type: FavoriteBooksOperationType.toggleFavorite,
              status: FavoriteBooksOperationStatus.completed,
            ),
          ));
          
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          _operationStopwatch.stop();
          dev.log('toggleFavorite failed after ${_operationStopwatch.elapsedMilliseconds}ms: $message');
          
          emit(state.copyWithBaseState(error: message, errorType: type));
          
          // Reload the original favorites to recover from error
          Future.delayed(const Duration(milliseconds: 100), () {
            loadInitialBooks();
          });
        },
      );
    } catch (e) {
      _operationStopwatch.stop();
      dev.log('Error toggling favorite after ${_operationStopwatch.elapsedMilliseconds}ms: $e');
      
      emit(state.copyWithBaseState(error: 'Failed to toggle favorite status: $e'));
      
      // Reload the original favorites to recover from error
      loadInitialBooks();
    }
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

  void _handleError(String message, FavoriteBooksOperationType operationType) {
    emit(state.copyWithBaseState(
      error: message,
      isLoading: false,
    ).copyWithOperation(FavoriteBooksOperation(
      type: operationType,
      status: FavoriteBooksOperationStatus.failed,
      message: message,
    )));
    
    _clearOperationAfterDelay();
  }

  void _clearOperationAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (state.currentOperation.status != FavoriteBooksOperationStatus.none) {
        emit(state.copyWithOperation(const FavoriteBooksOperation(status: FavoriteBooksOperationStatus.none)));
      }
    });
  }
}