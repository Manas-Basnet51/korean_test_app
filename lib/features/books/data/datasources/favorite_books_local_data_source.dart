import 'package:korean_language_app/features/books/data/models/book_item.dart';

abstract class FavoriteBooksLocalDataSource {
  Future<List<BookItem>> getAllBooks();
  Future<void> saveBooks(List<BookItem> books);
  Future<void> addBook(BookItem book);
  Future<void> removeBook(String bookId);
  Future<void> clearAllBooks();
  Future<bool> hasAnyBooks();
  Future<int> getBooksCount();
}