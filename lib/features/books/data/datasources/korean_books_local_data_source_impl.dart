import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:korean_language_app/features/books/data/datasources/korean_books_local_datasource.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KoreanBooksLocalDataSourceImpl implements KoreanBooksLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String cacheKey = 'CACHED_KOREAN_BOOKS';
  static const String lastCacheTimeKey = 'LAST_KOREAN_BOOKS_CACHE_TIME';
  
  KoreanBooksLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<BookItem>> getCachedKoreanBooks() async {
    try {
      final jsonString = sharedPreferences.getString(cacheKey);
      if (jsonString != null) {
        final List<dynamic> decodedJson = json.decode(jsonString);
        return decodedJson
            .map((item) => BookItem.fromJson(item))
            .toList();
      }
    } catch (e) {
      dev.log('Error decoding cached books: $e');
    }
    return [];
  }

  @override
  Future<void> cacheKoreanBooks(List<BookItem> books) async {
    if (books.isEmpty) {
      return;
    }
    
    try {
      final existingBooks = await getCachedKoreanBooks();
      
      // Create a map for O(1) lookups
      final Map<String, BookItem> uniqueBooks = {
        for (var book in existingBooks) book.id: book
      };
      
      // Add or update new books
      for (final book in books) {
        uniqueBooks[book.id] = book;
      }
      
      // Convert map values back to list
      final updatedBooks = uniqueBooks.values.toList();
      
      final List<Map<String, dynamic>> jsonList = 
          updatedBooks.map((book) => book.toJson()).toList();
      
      final String jsonString = json.encode(jsonList);
      await sharedPreferences.setString(cacheKey, jsonString);
      await sharedPreferences.setInt(lastCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
      
    } catch (e) {
      dev.log('Error caching books: $e');
    }
  }

  @override
  Future<bool> hasAnyCachedBooks() async {
    return sharedPreferences.containsKey(cacheKey);
  }

  @override
  Future<int> getCachedBooksCount() async {
    final books = await getCachedKoreanBooks();
    return books.length;
  }

  @override
  Future<void> clearCachedKoreanBooks() async {
    await sharedPreferences.remove(cacheKey);
    await sharedPreferences.remove(lastCacheTimeKey);
  }
  
  @override
  Future<void> updateBookMetadata(BookItem book) async {
    try {
      final existingBooks = await getCachedKoreanBooks();
      
      final index = existingBooks.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        existingBooks[index] = book;
        
        final List<Map<String, dynamic>> jsonList = 
            existingBooks.map((book) => book.toJson()).toList();
        
        final String jsonString = json.encode(jsonList);
        await sharedPreferences.setString(cacheKey, jsonString);
      } else {
        // If book wasn't found, add it to cache
        await cacheKoreanBooks([book]);
      }
    } catch (e) {
      dev.log('Error updating book metadata in cache: $e');
    }
  }
  
  @override
  Future<File?> getCachedPdfFile(String bookId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/pdf_cache/$bookId.pdf');
      
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize > 0) {
          return file;
        } else {
          // Delete invalid empty file
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
      
      // Create directory if it doesn't exist
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      final cacheFile = File('${cacheDir.path}/$bookId.pdf');
      
      // If file already exists, delete it first
      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }
      
      // Copy the file to cache
      await pdfFile.copy(cacheFile.path);
      
      // Verify the file was copied successfully
      if (await cacheFile.exists() && await cacheFile.length() > 0) {
        // Store the timestamp of when this PDF was cached
        final pdfCacheKey = 'PDF_CACHE_TIME_$bookId';
        final now = DateTime.now().millisecondsSinceEpoch;
        await sharedPreferences.setInt(pdfCacheKey, now);
      } else {
        dev.log('Failed to cache PDF file properly');
      }
    } catch (e) {
      dev.log('Error caching PDF file: $e');
    }
  }
  
  @override
  Future<bool> hasCachedPdf(String bookId) async {
    try {
      final file = await getCachedPdfFile(bookId);
      return file != null && await file.exists() && await file.length() > 0;
    } catch (e) {
      dev.log('Error checking for cached PDF: $e');
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
      
      // Clear the timestamp
      final pdfCacheKey = 'PDF_CACHE_TIME_$bookId';
      await sharedPreferences.remove(pdfCacheKey);
    } catch (e) {
      dev.log('Error clearing cached PDF: $e');
    }
  }
}