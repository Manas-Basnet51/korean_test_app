import 'dart:convert';

import 'package:korean_language_app/core/data/base_datasource.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/features/books/data/datasources/favorite_books_local_data_source.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteBooksLocalDataSourceImpl extends BaseDataSource implements FavoriteBooksLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String cacheKey = 'CACHED_FAVORITE_BOOKS';

  FavoriteBooksLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<ApiResult<List<BookItem>>> getCachedFavoriteBooks() {
    return handleDataSourceCall(() {
      final jsonString = sharedPreferences.getString(cacheKey);
      if (jsonString != null) {
        final List<dynamic> decodedJson = json.decode(jsonString);
        return decodedJson.map((item) => BookItem.fromJson(item)).toList();
      }
      return <BookItem>[];
    });
  }

  @override
  Future<ApiResult<void>> cacheFavoriteBooks(List<BookItem> books) {
    return handleAsyncDataSourceCall(() async {
      final existingBooksResult = await getCachedFavoriteBooks();
      final existingBooks = existingBooksResult.data ?? [];
      final updatedBooks = [...existingBooks, ...books];
      
      final List<Map<String, dynamic>> jsonList = 
          updatedBooks.map((book) => book.toJson()).toList();
      
      final String jsonString = json.encode(jsonList);
      await sharedPreferences.setString(cacheKey, jsonString);
    });
  }

  @override
  Future<ApiResult<bool>> hasAnyCachedBooks() {
    return handleDataSourceCall(() {
      return sharedPreferences.containsKey(cacheKey);
    });
  }

  @override
  Future<ApiResult<int>> getCachedBooksCount() {
    return handleAsyncDataSourceCall(() async {
      final books = await getCachedFavoriteBooks();
      return books.fold(
        onSuccess: (books) => books.length,
        onFailure: (_, __) => 0,
      );
    });
  }

  @override
  Future<ApiResult<void>> clearCachedFavoriteBooks() {
    return handleAsyncDataSourceCall(() async {
      await sharedPreferences.remove(cacheKey);
    });
  }

  @override
  Future<ApiResult<List<BookItem>>> removeBookFromCache(String bookId) {
    return handleAsyncDataSourceCall(() async {
      final booksResult = await getCachedFavoriteBooks();
      return booksResult.fold(
        onSuccess: (books) async {
          final updatedBooks = books.where((book) => book.id != bookId).toList();
          final jsonList = updatedBooks.map((book) => book.toJson()).toList();
          final jsonString = json.encode(jsonList);
          await sharedPreferences.setString(cacheKey, jsonString);
          return updatedBooks;
        },
        onFailure: (_, __) => [],
      );
    });
  }

  @override
  Future<ApiResult<List<BookItem>>> addFavoritedBook(BookItem book) {
    return handleAsyncDataSourceCall(() async {
      final booksResult = await getCachedFavoriteBooks();
      return booksResult.fold(
        onSuccess: (books) async {
          if (!books.any((b) => b.id == book.id)) {
            books.add(book);
            final jsonList = books.map((b) => b.toJson()).toList();
            final jsonString = json.encode(jsonList);
            await sharedPreferences.setString(cacheKey, jsonString);
          }
          return books;
        },
        onFailure: (_, __) => [book],
      );
    });
  }
}