import 'dart:convert';
import 'dart:developer' as dev;
import 'package:korean_language_app/features/books/data/datasources/favorite_books_local_data_source.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteBooksLocalDataSourceImpl implements FavoriteBooksLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String cacheKey = 'CACHED_FAVORITE_BOOKS';

  FavoriteBooksLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<BookItem>> getCachedFavoriteBooks() async {
    try {
      final jsonString = sharedPreferences.getString(cacheKey);
      if (jsonString == null) return [];
      
      final List<dynamic> decodedJson = json.decode(jsonString);
      final books = decodedJson.map((item) => BookItem.fromJson(item)).toList();
      
      // Validate and filter out corrupted entries
      final validBooks = books.where((book) => 
        book.id.isNotEmpty && 
        book.title.isNotEmpty && 
        book.description.isNotEmpty
      ).toList();
      
      // If we had to filter out corrupted books, update cache
      if (validBooks.length != books.length) {
        await _saveBooksToCache(validBooks);
      }
      
      return validBooks;
    } catch (e) {
      dev.log('Error reading cached favorite books: $e');
      await clearCachedFavoriteBooks();
      return [];
    }
  }

  @override
  Future<void> cacheFavoriteBooks(List<BookItem> books) async {
    try {
      await _saveBooksToCache(books);
    } catch (e) {
      dev.log('Error caching favorite books: $e');
      throw Exception('Failed to cache favorite books: $e');
    }
  }

  @override
  Future<bool> hasAnyCachedBooks() async {
    try {
      final books = await getCachedFavoriteBooks();
      return books.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> getCachedBooksCount() async {
    try {
      final books = await getCachedFavoriteBooks();
      return books.length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<void> clearCachedFavoriteBooks() async {
    try {
      await sharedPreferences.remove(cacheKey);
    } catch (e) {
      dev.log('Error clearing favorite books cache: $e');
    }
  }

  @override
  Future<List<BookItem>> removeBookFromCache(String bookId) async {
    try {
      final books = await getCachedFavoriteBooks();
      final updatedBooks = books.where((book) => book.id != bookId).toList();

      await _saveBooksToCache(updatedBooks);
      
      dev.log('Removed book from favorites: $bookId');
      return updatedBooks;
    } catch (e) {
      dev.log('Error removing book from favorites: $e');
      throw Exception('Failed to remove book from favorites: $e');
    }
  }

  @override
  Future<List<BookItem>> addFavoritedBook(BookItem book) async {
    try {
      final books = await getCachedFavoriteBooks();
      
      // Check if book is already in favorites
      if (!books.any((b) => b.id == book.id)) {
        books.add(book);
        
        // Sort by title for consistency
        books.sort((a, b) => a.title.compareTo(b.title));
        
        await _saveBooksToCache(books);
        
        dev.log('Added book to favorites: ${book.title}');
      } else {
        dev.log('Book already in favorites: ${book.title}');
      }
      
      return books;
    } catch (e) {
      dev.log('Error adding book to favorites: $e');
      throw Exception('Failed to add book to favorites: $e');
    }
  }

  Future<void> _saveBooksToCache(List<BookItem> books) async {
    final jsonList = books.map((book) => book.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await sharedPreferences.setString(cacheKey, jsonString);
  }
}