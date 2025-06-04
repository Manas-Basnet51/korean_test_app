import 'dart:developer' as dev;
import 'package:korean_language_app/core/data/base_repository.dart';
import 'package:korean_language_app/core/enums/course_category.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/core/network/network_info.dart';
import 'package:korean_language_app/features/books/data/datasources/favorite_books_local_data_source.dart';
import 'package:korean_language_app/features/books/domain/repositories/favorite_book_repository.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

class FavoriteBookRepositoryImpl extends BaseRepository implements FavoriteBookRepository {
  final FavoriteBooksLocalDataSource localDataSource;

  FavoriteBookRepositoryImpl({
    required this.localDataSource,
    required NetworkInfo networkInfo,
  }) : super(networkInfo);

  @override
  Future<ApiResult<void>> clearCachedBooks() async {
    try {
      await localDataSource.clearAllBooks();
      dev.log('Favorite books cache cleared successfully');
      return ApiResult.success(null);
    } catch (e) {
      dev.log('Failed to clear favorite books cache: $e');
      return ApiResult.failure('Failed to clear favorite books cache: $e', FailureType.cache);
    }
  }

  @override
  Future<ApiResult<List<BookItem>>> getBooks(CourseCategory category, {int page = 0, int pageSize = 5}) {
    // Favorites are always local, so just return all books
    return getBooksFromCache();
  }

  @override
  Future<ApiResult<List<BookItem>>> getBooksFromCache() async {
    try {
      final books = await localDataSource.getAllBooks();
      final validBooks = _filterValidBooks(books);
      dev.log('Retrieved ${validBooks.length} favorite books from cache');
      return ApiResult.success(validBooks);
    } catch (e) {
      dev.log('Failed to get favorite books from cache: $e');
      return ApiResult.failure('Failed to get favorite books from cache: $e', FailureType.cache);
    }
  }

  @override
  Future<ApiResult<List<BookItem>>> hardRefreshBooks(CourseCategory category, {int pageSize = 5}) {
    // For favorites, hard refresh is the same as getting from cache
    // since there's no remote source for favorites
    return getBooksFromCache();
  }

  @override
  Future<ApiResult<bool>> hasMoreBooks(CourseCategory category, int currentCount) async {
    try {
      final totalCount = await localDataSource.getBooksCount();
      final hasMore = currentCount < totalCount;
      dev.log('Favorite books hasMore check: $currentCount < $totalCount = $hasMore');
      return ApiResult.success(hasMore);
    } catch (e) {
      dev.log('Failed to check if more favorite books exist: $e');
      return ApiResult.success(false);
    }
  }

  @override
  Future<ApiResult<List<BookItem>>> searchBooks(CourseCategory category, String query) async {
    try {
      final allBooks = await localDataSource.getAllBooks();
      final validBooks = _filterValidBooks(allBooks);
      final normalizedQuery = query.toLowerCase().trim();
      
      if (normalizedQuery.isEmpty) {
        return ApiResult.success(validBooks);
      }
      
      final results = validBooks.where((book) {
        return book.title.toLowerCase().contains(normalizedQuery) ||
               book.description.toLowerCase().contains(normalizedQuery) ||
               book.category.toLowerCase().contains(normalizedQuery);
      }).toList();
      
      dev.log('Favorite books search for "$query" returned ${results.length} results');
      return ApiResult.success(results);
    } catch (e) {
      dev.log('Failed to search favorite books: $e');
      return ApiResult.failure('Failed to search favorite books: $e', FailureType.cache);
    }
  }
  
  @override
  Future<ApiResult<List<BookItem>>> addFavoritedBook(BookItem bookItem) async {
    try {
      await localDataSource.addBook(bookItem);
      final updatedBooks = await localDataSource.getAllBooks();
      final validBooks = _filterValidBooks(updatedBooks);
      
      dev.log('Added book to favorites: ${bookItem.title} (${bookItem.id})');
      return ApiResult.success(validBooks);
    } catch (e) {
      dev.log('Failed to add book to favorites: $e');
      return ApiResult.failure('Failed to add book to favorites: $e', FailureType.cache);
    }
  }

  @override
  Future<ApiResult<List<BookItem>>> removeBookFromFavorite(BookItem bookItem) async {
    try {
      await localDataSource.removeBook(bookItem.id);
      final updatedBooks = await localDataSource.getAllBooks();
      final validBooks = _filterValidBooks(updatedBooks);
      
      dev.log('Removed book from favorites: ${bookItem.title} (${bookItem.id})');
      return ApiResult.success(validBooks);
    } catch (e) {
      dev.log('Failed to remove book from favorites: $e');
      return ApiResult.failure('Failed to remove book from favorites: $e', FailureType.cache);
    }
  }

  // Additional helper methods for favorite-specific operations
  
  Future<ApiResult<bool>> isBookFavorited(String bookId) async {
    try {
      final favoriteBooks = await localDataSource.getAllBooks();
      final isFavorited = favoriteBooks.any((book) => book.id == bookId);
      return ApiResult.success(isFavorited);
    } catch (e) {
      dev.log('Failed to check if book is favorited: $e');
      return ApiResult.success(false);
    }
  }

  Future<ApiResult<int>> getFavoriteBooksCount() async {
    try {
      final count = await localDataSource.getBooksCount();
      return ApiResult.success(count);
    } catch (e) {
      dev.log('Failed to get favorite books count: $e');
      return ApiResult.success(0);
    }
  }

  Future<ApiResult<List<BookItem>>> getFavoriteBooksByCategory(String category) async {
    try {
      final allFavorites = await localDataSource.getAllBooks();
      final validBooks = _filterValidBooks(allFavorites);
      final filteredBooks = validBooks.where((book) => 
        book.category.toLowerCase() == category.toLowerCase()
      ).toList();
      
      return ApiResult.success(filteredBooks);
    } catch (e) {
      dev.log('Failed to get favorite books by category: $e');
      return ApiResult.failure('Failed to get favorite books by category: $e', FailureType.cache);
    }
  }

  Future<ApiResult<List<BookItem>>> getRecentlyFavoritedBooks({int limit = 5}) async {
    try {
      final allFavorites = await localDataSource.getAllBooks();
      final validBooks = _filterValidBooks(allFavorites);
      
      // Sort by creation date if available, otherwise by title
      validBooks.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        return a.title.compareTo(b.title);
      });
      
      final recentBooks = validBooks.take(limit).toList();
      return ApiResult.success(recentBooks);
    } catch (e) {
      dev.log('Failed to get recently favorited books: $e');
      return ApiResult.failure('Failed to get recently favorited books: $e', FailureType.cache);
    }
  }

  // Private helper methods
  List<BookItem> _filterValidBooks(List<BookItem> books) {
    return books.where((book) => 
      book.id.isNotEmpty && 
      book.title.isNotEmpty && 
      book.description.isNotEmpty
    ).toList();
  }
}