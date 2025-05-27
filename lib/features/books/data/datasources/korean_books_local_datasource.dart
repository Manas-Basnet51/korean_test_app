import 'dart:io';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

abstract class KoreanBooksLocalDataSource {
  Future<List<BookItem>> getCachedKoreanBooks();
  Future<void> cacheKoreanBooks(List<BookItem> books);
  Future<bool> hasAnyCachedBooks();
  Future<int> getCachedBooksCount();
  Future<void> clearCachedKoreanBooks();
  Future<void> updateBookMetadata(BookItem book);
  Future<void> removeBookFromCache(String bookId);
  
  // PDF caching
  Future<File?> getCachedPdfFile(String bookId);
  Future<void> cachePdfFile(String bookId, File pdfFile);
  Future<bool> hasCachedPdf(String bookId);
  Future<void> clearCachedPdf(String bookId);
  
  Future<bool> isCacheValid();
  Future<void> invalidateCache();
  Future<List<String>> getDeletedBookIds(List<BookItem> remoteBooks);
  Future<bool> hasBookChanged(BookItem book);
  Future<void> markBookAsSynced(BookItem book);
  Future<CacheHealthStatus> checkCacheHealth();
}

class CacheHealthStatus {
  final bool isValid;
  final int bookCount;
  final bool hasCorruptedEntries;
  final DateTime? lastSyncTime;

  CacheHealthStatus({
    required this.isValid,
    required this.bookCount,
    required this.hasCorruptedEntries,
    this.lastSyncTime,
  });

  bool get isHealthy => isValid && !hasCorruptedEntries && bookCount > 0;
  
  @override
  String toString() {
    return 'CacheHealthStatus(isValid: $isValid, bookCount: $bookCount, hasCorruptedEntries: $hasCorruptedEntries, lastSyncTime: $lastSyncTime)';
  }
}