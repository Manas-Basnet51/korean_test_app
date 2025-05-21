import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/enums/course_category.dart';
import 'package:korean_language_app/features/books/domain/repositories/favorite_book_repository.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

part 'favorite_books_state.dart';

class FavoriteBooksCubit extends Cubit<FavoriteBooksState> {
  final FavoriteBookRepository repository;
  
  FavoriteBooksCubit(this.repository) : super(FavoriteBooksInitial());
  
  Future loadInitialBooks() async {
    log('loadFavInitialBooks');
    
    state is FavoriteBooksLoaded ? null : emit(FavoriteBooksLoading());
    
    try {
      List<BookItem> books = await repository.getBooksFromCache();

      // Ensure no duplicates in the cached books
      final uniqueBooks = _removeDuplicates(books);
      
      bool hasMoreBooks;
      
      if(state is FavoriteBooksLoaded) {
        hasMoreBooks = (state as FavoriteBooksLoaded).hasMore;
      }
      else {
        hasMoreBooks = await repository.hasMoreBooks(CourseCategory.favorite, uniqueBooks.length);
      }
      
      emit(FavoriteBooksLoaded(uniqueBooks, hasMoreBooks));
    } catch (e) {
      emit(FavoriteBooksError('Failed to load Favorite books: $e'));
    }
  }
  
  // Hard refresh function
  Future hardRefresh() async {
    log('hardRefreshFav');
    emit(FavoriteBooksLoading());
    
    try {
      final books = await repository.getBooksFromCache();
      // Ensure no duplicates in the refreshed books
      final uniqueBooks = _removeDuplicates(books);
      
      final hasMore = await repository.hasMoreBooks(CourseCategory.favorite, uniqueBooks.length);
      
      emit(FavoriteBooksLoaded(uniqueBooks, hasMore));
    } catch (e) {
      emit(FavoriteBooksError('Failed to refresh Favorite books: $e'));
    }
  }
  
  Future searchBooks(String query) async {

    emit(FavoriteBooksLoading());
    
    try {
      final searchResults = await repository.searchBooks(CourseCategory.favorite, query);
      
      // Ensure no duplicates in search results
      final uniqueSearchResults = _removeDuplicates(searchResults);
      
      // Emit the search results - no pagination for search results so hasMore is false
      emit(FavoriteBooksLoaded(uniqueSearchResults, false));
    } catch (e) {
      emit(FavoriteBooksError('Failed to search books: $e'));
    }
  }

  Future<void> toggleFavorite(BookItem bookItem) async {
    try {
      List<BookItem> updatedBooks = [];
      
      // Check if book is already in favorites
      if (state is FavoriteBooksLoaded) {
        final currentBooks = (state as FavoriteBooksLoaded).books;
        final bool isAlreadyFavorite = currentBooks.any((book) => book.id == bookItem.id);
        
        // If already in favorites, remove it
        if (isAlreadyFavorite) {
          updatedBooks = await repository.removeBookFromFavorite(bookItem);
        } 
        // If not in favorites, add it
        else {
          updatedBooks = await repository.addFavoritedBook(bookItem);
        }
        
        final hasMore = await repository.hasMoreBooks(CourseCategory.favorite, updatedBooks.length);
        emit(FavoriteBooksLoaded(updatedBooks, hasMore));
      } else {
        // If state is not loaded yet, just add the book
        updatedBooks = await repository.addFavoritedBook(bookItem);
        emit(FavoriteBooksLoaded(updatedBooks, false));
      }
    } catch (e) {
      emit(FavoriteBooksError('Failed to toggle favorite status: $e'));
      // Reload the original favorites to recover from error
      loadInitialBooks();
    }
  }
  
  // Helper method to remove duplicate books based on ID
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