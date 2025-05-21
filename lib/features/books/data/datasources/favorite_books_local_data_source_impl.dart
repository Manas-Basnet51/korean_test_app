import 'dart:convert';

import 'package:korean_language_app/features/books/data/datasources/favorite_books_local_data_source.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteBooksLocalDataSourceImpl implements FavoriteBooksLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String cacheKey = 'CACHED_FAVORITE_BOOKS';

  FavoriteBooksLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<BookItem>> getCachedFavoriteBooks() async {
    final jsonString = sharedPreferences.getString(cacheKey);
    if (jsonString != null) {
      final List<dynamic> decodedJson = json.decode(jsonString);
      return decodedJson
          .map((item) => BookItem.fromJson(item))
          .toList();
    }
    return [];
  }

  @override
  Future<void> cacheFavoriteBooks(List<BookItem> books) async {
    final existingBooks = await getCachedFavoriteBooks();
    final updatedBooks = [...existingBooks, ...books];
    
    final List<Map<String, dynamic>> jsonList = 
        updatedBooks.map((book) => book.toJson()).toList();
    
    final String jsonString = json.encode(jsonList);
    await sharedPreferences.setString(cacheKey, jsonString);
  }

  @override
  Future<bool> hasAnyCachedBooks() async {
    return sharedPreferences.containsKey(cacheKey);
  }

  @override
  Future<int> getCachedBooksCount() async {
    final books = await getCachedFavoriteBooks();
    return books.length;
  }

  @override
  Future<void> clearCachedFavoriteBooks() async {
    await sharedPreferences.remove(cacheKey);
  }

  @override
  Future<List<BookItem>> removeBookFromCache(String bookId) async {
    final books = await getCachedFavoriteBooks();
    final updatedBooks = books.where((book) => book.id != bookId).toList();

    final List<Map<String, dynamic>> jsonList =
        updatedBooks.map((book) => book.toJson()).toList();

    final String jsonString = json.encode(jsonList);
    await sharedPreferences.setString(cacheKey, jsonString);
    return await getCachedFavoriteBooks();
  }

  @override
  Future<List<BookItem>> addFavoritedBook(BookItem book) async {
    final books = await getCachedFavoriteBooks();
    
    // Avoiding adding duplicate books based on their unique ID
    if (!books.any((b) => b.id == book.id)) {
      books.add(book);
      
      final List<Map<String, dynamic>> jsonList =
          books.map((b) => b.toJson()).toList();

      final String jsonString = json.encode(jsonList);
      await sharedPreferences.setString(cacheKey, jsonString);
    }
    return await getCachedFavoriteBooks();
  }

}
