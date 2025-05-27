
import 'package:korean_language_app/features/books/data/models/book_item.dart';

abstract class FavoriteBooksLocalDataSource {
  Future<List<BookItem>> getCachedFavoriteBooks();
  Future<void> cacheFavoriteBooks(List<BookItem> books);
  Future<bool> hasAnyCachedBooks();
  Future<int> getCachedBooksCount();
  Future<void> clearCachedFavoriteBooks();
  Future<List<BookItem>> removeBookFromCache(String bookId);
  Future<List<BookItem>> addFavoritedBook(BookItem book);
}