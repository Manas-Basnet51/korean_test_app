import 'dart:io';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

abstract class KoreanBooksLocalDataSource {
  Future<List<BookItem>> getAllBooks();
  Future<void> saveBooks(List<BookItem> books);
  Future<void> addBook(BookItem book);
  Future<void> updateBook(BookItem book);
  Future<void> removeBook(String bookId);
  Future<void> clearAllBooks();
  Future<bool> hasAnyBooks();
  Future<int> getBooksCount();
  
  // metadata operations
  Future<void> setLastSyncTime(DateTime dateTime);
  Future<DateTime?> getLastSyncTime();
  Future<void> setBookHashes(Map<String, String> hashes);
  Future<Map<String, String>> getBookHashes();
  
  // PDF file operations
  Future<File?> getPdfFile(String bookId);
  Future<void> savePdfFile(String bookId, File pdfFile);
  Future<bool> hasPdfFile(String bookId);
  Future<void> deletePdfFile(String bookId);
}