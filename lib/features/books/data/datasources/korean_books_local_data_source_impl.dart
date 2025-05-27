import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:korean_language_app/features/books/data/datasources/korean_books_local_datasource.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KoreanBooksLocalDataSourceImpl implements KoreanBooksLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String booksKey = 'CACHED_KOREAN_BOOKS';
  static const String lastSyncKey = 'LAST_BOOKS_SYNC_TIME';
  static const String bookHashesKey = 'BOOK_HASHES';
  
  static const Duration cacheValidityDuration = Duration(hours: 1);

  KoreanBooksLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<BookItem>> getCachedKoreanBooks() async {
    try {
      final jsonString = sharedPreferences.getString(booksKey);
      if (jsonString == null) return [];
      
      final List<dynamic> decodedJson = json.decode(jsonString);
      final books = decodedJson.map((item) => BookItem.fromJson(item)).toList();
      
      final validBooks = books.where((book) => 
        book.id.isNotEmpty && 
        book.title.isNotEmpty && 
        book.description.isNotEmpty
      ).toList();
      
      if (validBooks.length != books.length) {
        await _saveBooksToCache(validBooks);
      }
      
      return validBooks;
    } catch (e) {
      dev.log('Error reading cached books: $e');
      await clearCachedKoreanBooks();
      return [];
    }
  }

  @override
  Future<void> cacheKoreanBooks(List<BookItem> books) async {
    if (books.isEmpty) return;
    
    try {
      final existingBooks = await getCachedKoreanBooks();
      final mergedBooks = _mergeBooks(existingBooks, books);
      await _saveBooksToCache(mergedBooks);
      
      await sharedPreferences.setInt(lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      await _updateBookHashes(mergedBooks);
      
    } catch (e) {
      dev.log('Error caching books: $e');
      throw Exception('Failed to cache books: $e');
    }
  }

  @override
  Future<bool> hasAnyCachedBooks() async {
    try {
      final books = await getCachedKoreanBooks();
      return books.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> getCachedBooksCount() async {
    try {
      final books = await getCachedKoreanBooks();
      return books.length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<void> clearCachedKoreanBooks() async {
    try {
      await sharedPreferences.remove(booksKey);
      await sharedPreferences.remove(lastSyncKey);
      await sharedPreferences.remove(bookHashesKey);
    } catch (e) {
      dev.log('Error clearing cache: $e');
    }
  }

  @override
  Future<void> updateBookMetadata(BookItem book) async {
    try {
      final existingBooks = await getCachedKoreanBooks();
      final bookIndex = existingBooks.indexWhere((b) => b.id == book.id);
      
      if (bookIndex != -1) {
        existingBooks[bookIndex] = book;
      } else {
        existingBooks.add(book);
      }
      
      await _saveBooksToCache(existingBooks);
      await _updateBookHashes(existingBooks);
    } catch (e) {
      dev.log('Error updating book metadata: $e');
      throw Exception('Failed to update book metadata: $e');
    }
  }

  @override
  Future<void> removeBookFromCache(String bookId) async {
    try {
      final existingBooks = await getCachedKoreanBooks();
      final updatedBooks = existingBooks.where((book) => book.id != bookId).toList();
      
      await _saveBooksToCache(updatedBooks);
      await _updateBookHashes(updatedBooks);
    } catch (e) {
      dev.log('Error removing book from cache: $e');
      throw Exception('Failed to remove book from cache: $e');
    }
  }

  @override
  Future<File?> getCachedPdfFile(String bookId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/pdf_cache/$bookId.pdf');
      
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize > 0 && await _isValidPDF(file)) {
          return file;
        } else {
          await file.delete();
        }
      }
      return null;
    } catch (e) {
      dev.log('Error getting cached PDF: $e');
      return null;
    }
  }
  
  @override
  Future<void> cachePdfFile(String bookId, File pdfFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/pdf_cache');
      
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      final cacheFile = File('${cacheDir.path}/$bookId.pdf');
      
      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }
      
      await pdfFile.copy(cacheFile.path);
      
      if (await cacheFile.exists() && await cacheFile.length() > 0) {
        final pdfCacheKey = 'PDF_CACHE_TIME_$bookId';
        final now = DateTime.now().millisecondsSinceEpoch;
        await sharedPreferences.setInt(pdfCacheKey, now);
      } else {
        throw Exception('Failed to cache PDF file properly');
      }
    } catch (e) {
      dev.log('Error caching PDF: $e');
      throw Exception('Failed to cache PDF file: $e');
    }
  }
  
  @override
  Future<bool> hasCachedPdf(String bookId) async {
    try {
      final file = await getCachedPdfFile(bookId);
      return file != null && await file.exists() && await file.length() > 0;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<void> clearCachedPdf(String bookId) async {
    try {
      final file = await getCachedPdfFile(bookId);
      if (file != null && await file.exists()) {
        await file.delete();
      }
      
      final pdfCacheKey = 'PDF_CACHE_TIME_$bookId';
      await sharedPreferences.remove(pdfCacheKey);
    } catch (e) {
      dev.log('Error clearing cached PDF: $e');
    }
  }

  @override
  Future<bool> isCacheValid() async {
    try {
      final lastSyncTimestamp = sharedPreferences.getInt(lastSyncKey);
      if (lastSyncTimestamp == null) return false;
      
      final lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncTimestamp);
      final cacheAge = DateTime.now().difference(lastSync);
      
      return cacheAge < cacheValidityDuration;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> invalidateCache() async {
    await sharedPreferences.remove(lastSyncKey);
  }

  @override
  Future<List<String>> getDeletedBookIds(List<BookItem> remoteBooks) async {
    try {
      final cachedBooks = await getCachedKoreanBooks();
      final remoteBookIds = remoteBooks.map((book) => book.id).toSet();
      
      final deletedIds = cachedBooks
          .where((book) => !remoteBookIds.contains(book.id))
          .map((book) => book.id)
          .toList();
      
      return deletedIds;
    } catch (e) {
      dev.log('Error detecting deleted books: $e');
      return [];
    }
  }

  @override
  Future<bool> hasBookChanged(BookItem book) async {
    try {
      final hashesJson = sharedPreferences.getString(bookHashesKey);
      if (hashesJson == null) return true;
      
      final Map<String, dynamic> hashes = json.decode(hashesJson);
      final currentHash = _generateBookHash(book);
      final storedHash = hashes[book.id];
      
      return currentHash != storedHash;
    } catch (e) {
      return true;
    }
  }

  @override
  Future<void> markBookAsSynced(BookItem book) async {
    try {
      final hashesJson = sharedPreferences.getString(bookHashesKey);
      final Map<String, dynamic> hashes = hashesJson != null 
          ? json.decode(hashesJson)
          : <String, dynamic>{};
      
      hashes[book.id] = _generateBookHash(book);
      
      await sharedPreferences.setString(bookHashesKey, json.encode(hashes));
    } catch (e) {
      dev.log('Error marking book as synced: $e');
    }
  }

  @override
  Future<CacheHealthStatus> checkCacheHealth() async {
    try {
      final books = await getCachedKoreanBooks();
      final isValid = await isCacheValid();
      final hasCorruptedEntries = books.any((book) => 
        book.id.isEmpty || book.title.isEmpty || book.description.isEmpty
      );
      
      return CacheHealthStatus(
        isValid: isValid,
        bookCount: books.length,
        hasCorruptedEntries: hasCorruptedEntries,
        lastSyncTime: DateTime.fromMillisecondsSinceEpoch(
          sharedPreferences.getInt(lastSyncKey) ?? 0
        ),
      );
    } catch (e) {
      return CacheHealthStatus(
        isValid: false,
        bookCount: 0,
        hasCorruptedEntries: true,
        lastSyncTime: null,
      );
    }
  }

  Future<void> _saveBooksToCache(List<BookItem> books) async {
    final jsonList = books.map((book) => book.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await sharedPreferences.setString(booksKey, jsonString);
  }

  List<BookItem> _mergeBooks(List<BookItem> existing, List<BookItem> newBooks) {
    final Map<String, BookItem> bookMap = {};
    
    for (final book in existing) {
      bookMap[book.id] = book;
    }
    
    for (final book in newBooks) {
      bookMap[book.id] = book;
    }
    
    final mergedBooks = bookMap.values.toList();
    mergedBooks.sort((a, b) => a.title.compareTo(b.title));
    
    return mergedBooks;
  }

  Future<void> _updateBookHashes(List<BookItem> books) async {
    try {
      final Map<String, String> hashes = {};
      for (final book in books) {
        hashes[book.id] = _generateBookHash(book);
      }
      
      await sharedPreferences.setString(bookHashesKey, json.encode(hashes));
    } catch (e) {
      dev.log('Error updating book hashes: $e');
    }
  }

  String _generateBookHash(BookItem book) {
    final content = '${book.title}_${book.description}_${book.updatedAt?.millisecondsSinceEpoch ?? 0}';
    return content.hashCode.toString();
  }

  Future<bool> _isValidPDF(File pdfFile) async {
    try {
      if (!await pdfFile.exists()) return false;
      
      final fileSize = await pdfFile.length();
      if (fileSize < 1024) return false; // Too small to be valid PDF
      
      // Check PDF header
      final bytes = await pdfFile.readAsBytes();
      if (bytes.length < 4) return false;
      
      final header = String.fromCharCodes(bytes.take(4));
      return header == '%PDF';
      
    } catch (e) {
      return false;
    }
  }
}