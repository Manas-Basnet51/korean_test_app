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
  Future<ApiResult<void>> clearCachedBooks() {
    return localDataSource.clearCachedFavoriteBooks();
  }

  @override
  Future<ApiResult<List<BookItem>>> getBooks(CourseCategory category, {int page = 0, int pageSize = 5}) {
    return getBooksFromCache();
  }

  @override
  Future<ApiResult<List<BookItem>>> getBooksFromCache() {
    return localDataSource.getCachedFavoriteBooks();
  }

  @override
  Future<ApiResult<List<BookItem>>> hardRefreshBooks(CourseCategory category, {int pageSize = 5}) {
    return getBooksFromCache();
  }

  @override
  Future<ApiResult<bool>> hasMoreBooks(CourseCategory category, int currentCount) async {
    final totalCachedCountResult = await localDataSource.getCachedBooksCount();
    return totalCachedCountResult.fold(
      onSuccess: (totalCount) => ApiResult.success(currentCount < totalCount),
      onFailure: (message, type) => ApiResult.failure(message, type),
    );
  }

  @override
  Future<ApiResult<List<BookItem>>> searchBooks(CourseCategory category, String query) async {
    return _searchInCache(query);
  }
  
  @override
  Future<ApiResult<List<BookItem>>> addFavoritedBook(BookItem bookItem) {
    return localDataSource.addFavoritedBook(bookItem);
  }

  @override
  Future<ApiResult<List<BookItem>>> removeBookFromFavorite(BookItem bookItem) {
    return localDataSource.removeBookFromCache(bookItem.id);
  }

  Future<ApiResult<List<BookItem>>> _searchInCache(String query) async {
    final allCachedBooksResult = await getBooksFromCache();
    if (!allCachedBooksResult.isSuccess) {
      return allCachedBooksResult;
    }
    
    final allCachedBooks = allCachedBooksResult.data!;
    final normalizedQuery = query.toLowerCase();
    
    final results = allCachedBooks.where((book) {
      return book.title.toLowerCase().contains(normalizedQuery) ||
            book.description.toLowerCase().contains(normalizedQuery);
    }).toList();
    
    return ApiResult.success(results);
  }
}