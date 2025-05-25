import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/data/base_state.dart';
import 'package:korean_language_app/core/enums/course_category.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/features/books/domain/repositories/favorite_book_repository.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

part 'favorite_books_state.dart';

class FavoriteBooksCubit extends Cubit<FavoriteBooksState> {
  final FavoriteBookRepository repository;
  
  // Cache for state
  FavoriteBooksState? _cachedState;
  
  FavoriteBooksState? get cachedState => _cachedState;
  
  FavoriteBooksCubit(this.repository) : super(const FavoriteBooksInitial());
  
  Future<void> loadInitialBooks() async {
    log('loadFavInitialBooks');
    
    try {
      // Only show loading if we don't have cached data
      if (_cachedState == null || _cachedState!.books.isEmpty) {
        emit(state.copyWith(
          isLoading: true,
          currentOperation: const FavoriteBooksOperation(
            type: FavoriteBooksOperationType.loadBooks,
            status: FavoriteBooksOperationStatus.inProgress,
          ),
        ));
      }
      
      final result = await repository.getBooksFromCache();
      
      result.fold(
        onSuccess: (books) async {
          final uniqueBooks = _removeDuplicates(books);
          
          final hasMoreResult = await repository.hasMoreBooks(CourseCategory.favorite, uniqueBooks.length);
          
          final newState = FavoriteBooksState(
            books: uniqueBooks,
            hasMore: hasMoreResult.fold(
              onSuccess: (hasMore) => hasMore,
              onFailure: (_, __) => false,
            ),
            currentOperation: const FavoriteBooksOperation(
              type: FavoriteBooksOperationType.loadBooks,
              status: FavoriteBooksOperationStatus.completed,
            ),
          );
          
          _cachedState = newState;
          emit(newState);
          
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          if (_cachedState != null && _cachedState!.books.isNotEmpty) {
            emit(_cachedState!.copyWithBaseState(error: message, errorType: type));
            Future.delayed(const Duration(milliseconds: 100), () {
              emit(_cachedState!);
            });
          } else {
            emit(state.copyWithBaseState(
              error: message,
              errorType: type,
              isLoading: false,
            ).copyWithOperation(const FavoriteBooksOperation(
              type: FavoriteBooksOperationType.loadBooks,
              status: FavoriteBooksOperationStatus.failed,
            )));
          }
        },
      );
    } catch (e) {
      log('Error loading favorite books: $e');
      _handleError('Failed to load Favorite books: $e', FavoriteBooksOperationType.loadBooks);
    }
  }
  
  Future<void> hardRefresh() async {
    log('hardRefreshFav');
    
    try {
      emit(state.copyWith(
        isLoading: true,
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
          
          final newState = FavoriteBooksState(
            books: uniqueBooks,
            hasMore: hasMoreResult.fold(
              onSuccess: (hasMore) => hasMore,
              onFailure: (_, __) => false,
            ),
            currentOperation: const FavoriteBooksOperation(
              type: FavoriteBooksOperationType.refreshBooks,
              status: FavoriteBooksOperationStatus.completed,
            ),
          );
          
          _cachedState = newState;
          emit(newState);
          
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          if (_cachedState != null && _cachedState!.books.isNotEmpty) {
            emit(_cachedState!.copyWithBaseState(error: message, errorType: type));
            Future.delayed(const Duration(milliseconds: 100), () {
              emit(_cachedState!);
            });
          } else {
            emit(state.copyWithBaseState(
              error: message,
              errorType: type,
              isLoading: false,
            ).copyWithOperation(const FavoriteBooksOperation(
              type: FavoriteBooksOperationType.refreshBooks,
              status: FavoriteBooksOperationStatus.failed,
            )));
          }
        },
      );
    } catch (e) {
      log('Error refreshing favorite books: $e');
      _handleError('Failed to refresh Favorite books: $e', FavoriteBooksOperationType.refreshBooks);
    }
  }
  
  Future<void> searchBooks(String query) async {
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
          
          final newState = state.copyWith(
            books: uniqueSearchResults,
            hasMore: false, // No pagination for search results
            isLoading: false,
            currentOperation: const FavoriteBooksOperation(
              type: FavoriteBooksOperationType.searchBooks,
              status: FavoriteBooksOperationStatus.completed,
            ),
          );
          
          emit(newState);
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          if (_cachedState != null && _cachedState!.books.isNotEmpty) {
            emit(_cachedState!.copyWithBaseState(error: message, errorType: type));
            Future.delayed(const Duration(milliseconds: 100), () {
              emit(_cachedState!);
            });
          } else {
            emit(state.copyWithBaseState(
              error: message,
              errorType: type,
              isLoading: false,
            ).copyWithOperation(const FavoriteBooksOperation(
              type: FavoriteBooksOperationType.searchBooks,
              status: FavoriteBooksOperationStatus.failed,
            ))); 
          }
        },
      );
    } catch (e) {
      log('Error searching favorite books: $e');
      _handleError('Failed to search books: $e', FavoriteBooksOperationType.searchBooks);
    }
  }

  Future<void> toggleFavorite(BookItem bookItem) async {
    try {
      emit(state.copyWith(
        currentOperation: const FavoriteBooksOperation(
          type: FavoriteBooksOperationType.toggleFavorite,
          status: FavoriteBooksOperationStatus.inProgress,
        ),
      ));
      
      final currentBooks = state.books;
      final bool isAlreadyFavorite = currentBooks.any((book) => book.id == bookItem.id);
      
      ApiResult<List<BookItem>> result;
      
      if (isAlreadyFavorite) {
        result = await repository.removeBookFromFavorite(bookItem);
      } else {
        result = await repository.addFavoritedBook(bookItem);
      }
      
      result.fold(
        onSuccess: (updatedBooks) async {
          final hasMoreResult = await repository.hasMoreBooks(CourseCategory.favorite, updatedBooks.length);
          
          final newState = state.copyWith(
            books: updatedBooks,
            hasMore: hasMoreResult.fold(
              onSuccess: (hasMore) => hasMore,
              onFailure: (_, __) => false,
            ),
            currentOperation: const FavoriteBooksOperation(
              type: FavoriteBooksOperationType.toggleFavorite,
              status: FavoriteBooksOperationStatus.completed,
            ),
          );
          
          _cachedState = newState;
          emit(newState);
          
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          emit(state.copyWithBaseState(error: message, errorType: type));
          
          // Reload the original favorites to recover from error
          Future.delayed(const Duration(milliseconds: 100), () {
            loadInitialBooks();
          });
        },
      );
    } catch (e) {
      log('Error toggling favorite: $e');
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
    if (_cachedState != null && _cachedState!.books.isNotEmpty) {
      emit(_cachedState!.copyWithBaseState(error: message));
      Future.delayed(const Duration(milliseconds: 100), () {
        emit(_cachedState!.copyWithOperation(FavoriteBooksOperation(
          type: operationType,
          status: FavoriteBooksOperationStatus.failed,
          message: message,
        )));
      });
    } else {
      emit(state.copyWithBaseState(
        error: message,
        isLoading: false,
      ).copyWithOperation(FavoriteBooksOperation(
        type: operationType,
        status: FavoriteBooksOperationStatus.failed,
        message: message,
      )));
    }
    
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