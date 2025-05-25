
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

abstract class FavoriteBooksLocalDataSource {
  Future<ApiResult<List<BookItem>>> getCachedFavoriteBooks();
  Future<ApiResult<void>> cacheFavoriteBooks(List<BookItem> books);
  Future<ApiResult<bool>> hasAnyCachedBooks();
  Future<ApiResult<int>> getCachedBooksCount();
  Future<ApiResult<void>> clearCachedFavoriteBooks();
  Future<ApiResult<List<BookItem>>> removeBookFromCache(String bookId);
  Future<ApiResult<List<BookItem>>> addFavoritedBook(BookItem book);
}