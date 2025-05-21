import 'dart:io';

import 'package:korean_language_app/features/books/data/models/book_item.dart';

abstract class KoreanBooksLocalDataSource {
  Future<List<BookItem>> getCachedKoreanBooks();
  Future<void> cacheKoreanBooks(List<BookItem> books);
  Future<bool> hasAnyCachedBooks();
  Future<int> getCachedBooksCount();
  Future<void> clearCachedKoreanBooks();
  
  Future<File?> getCachedPdfFile(String bookId);
  Future<void> cachePdfFile(String bookId, File pdfFile);
  Future<bool> hasCachedPdf(String bookId);
  Future<void> clearCachedPdf(String bookId);
  Future<void> updateBookMetadata(BookItem book);
}