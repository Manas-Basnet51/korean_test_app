import 'package:korean_language_app/core/enums/course_category.dart';
import 'package:korean_language_app/core/network/network_info.dart';
import 'package:korean_language_app/features/books/data/datasources/favorite_books_local_data_source.dart';
import 'package:korean_language_app/features/books/domain/repositories/favorite_book_repository.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

class FavoriteBookRepositoryImpl implements FavoriteBookRepository {
  final FavoriteBooksLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  FavoriteBookRepositoryImpl({
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future clearCachedBooks() async {
    await await localDataSource.clearCachedFavoriteBooks();
  }

  @override
  Future<List<BookItem>> getBooks(CourseCategory category, {int page = 0, int pageSize = 5}) async {
    return await getBooksFromCache();
  }

  @override
  Future<List<BookItem>> getBooksFromCache() async {
    return await localDataSource.getCachedFavoriteBooks();
  }

  @override
  Future<List<BookItem>> hardRefreshBooks(CourseCategory category, {int pageSize = 5}) async {
    return await getBooksFromCache();
  }

  @override
  Future<bool> hasMoreBooks(CourseCategory category, int currentCount) async {
      final totalCachedCount = await localDataSource.getCachedBooksCount();
      return currentCount < totalCachedCount;
  }

  @override
  Future<List<BookItem>> searchBooks(CourseCategory category, String query) async {
    final cachedResults = await searchInCache(query);
    return cachedResults;
  }
  
  @override
  Future<List<BookItem>> addFavoritedBook(BookItem bookItem) async {
    return await localDataSource.addFavoritedBook(bookItem);
  }

  @override
  Future<List<BookItem>> removeBookFromFavorite(BookItem bookItem) async {
    return await localDataSource.removeBookFromCache(bookItem.id);
  }

  //Helper method to search in cache
  Future<List<BookItem>> searchInCache(String query) async {
    final allCachedBooks = await getBooksFromCache();
    final normalizedQuery = query.toLowerCase();
    
    return allCachedBooks.where((book) {
      return book.title.toLowerCase().contains(normalizedQuery) ||
            book.description.toLowerCase().contains(normalizedQuery);
    }).toList();
  }
  
}