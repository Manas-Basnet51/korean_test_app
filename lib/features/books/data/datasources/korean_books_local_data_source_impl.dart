import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:korean_language_app/core/data/base_datasource.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/features/books/data/datasources/korean_books_local_datasource.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KoreanBooksLocalDataSourceImpl extends BaseDataSource implements KoreanBooksLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String cacheKey = 'CACHED_KOREAN_BOOKS';
  static const String lastCacheTimeKey = 'LAST_KOREAN_BOOKS_CACHE_TIME';
  
  KoreanBooksLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<ApiResult<List<BookItem>>> getCachedKoreanBooks() {
    return handleAsyncDataSourceCall(() async {
      final jsonString = sharedPreferences.getString(cacheKey);
      if (jsonString != null) {
        final List<dynamic> decodedJson = json.decode(jsonString);
        return decodedJson
            .map((item) => BookItem.fromJson(item))
            .toList();
      }
      return <BookItem>[];
    });
  }

  @override
  Future<ApiResult<void>> cacheKoreanBooks(List<BookItem> books) {
    return handleAsyncDataSourceCall(() async {
      if (books.isEmpty) {
        return;
      }
      
      final existingBooksResult = await getCachedKoreanBooks();
      if (!existingBooksResult.isSuccess) {
        throw Exception('Failed to get existing cached books');
      }
      
      final existingBooks = existingBooksResult.data!;
      
      final Map<String, BookItem> uniqueBooks = {
        for (var book in existingBooks) book.id: book
      };
      
      for (final book in books) {
        uniqueBooks[book.id] = book;
      }
      
      final updatedBooks = uniqueBooks.values.toList();
      
      final List<Map<String, dynamic>> jsonList = 
          updatedBooks.map((book) => book.toJson()).toList();
      
      final String jsonString = json.encode(jsonList);
      await sharedPreferences.setString(cacheKey, jsonString);
      await sharedPreferences.setInt(lastCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    });
  }

  @override
  Future<ApiResult<bool>> hasAnyCachedBooks() {
    return handleDataSourceCall(() {
      return sharedPreferences.containsKey(cacheKey);
    });
  }

  @override
  Future<ApiResult<int>> getCachedBooksCount() {
    return handleAsyncDataSourceCall(() async {
      final booksResult = await getCachedKoreanBooks();
      if (!booksResult.isSuccess) {
        throw Exception('Failed to get cached books count');
      }
      return booksResult.data!.length;
    });
  }

  @override
  Future<ApiResult<void>> clearCachedKoreanBooks() {
    return handleAsyncDataSourceCall(() async {
      await sharedPreferences.remove(cacheKey);
      await sharedPreferences.remove(lastCacheTimeKey);
    });
  }
  
  @override
  Future<ApiResult<void>> updateBookMetadata(BookItem book) {
    return handleAsyncDataSourceCall(() async {
      final existingBooksResult = await getCachedKoreanBooks();
      if (!existingBooksResult.isSuccess) {
        throw Exception('Failed to get existing cached books');
      }
      
      final existingBooks = existingBooksResult.data!;
      
      final index = existingBooks.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        existingBooks[index] = book;
        
        final List<Map<String, dynamic>> jsonList = 
            existingBooks.map((book) => book.toJson()).toList();
        
        final String jsonString = json.encode(jsonList);
        await sharedPreferences.setString(cacheKey, jsonString);
      } else {
        final cacheResult = await cacheKoreanBooks([book]);
        if (!cacheResult.isSuccess) {
          throw Exception('Failed to cache book');
        }
      }
    });
  }
  
  @override
  Future<ApiResult<File?>> getCachedPdfFile(String bookId) {
    return handleAsyncDataSourceCall(() async {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/pdf_cache/$bookId.pdf');
      
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize > 0) {
          return file;
        } else {
          await file.delete();
        }
      }
      return null;
    });
  }
  
  @override
  Future<ApiResult<void>> cachePdfFile(String bookId, File pdfFile) {
    return handleAsyncDataSourceCall(() async {
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
        dev.log('Failed to cache PDF file properly');
        throw Exception('Failed to cache PDF file properly');
      }
    });
  }
  
  @override
  Future<ApiResult<bool>> hasCachedPdf(String bookId) {
    return handleAsyncDataSourceCall(() async {
      final fileResult = await getCachedPdfFile(bookId);
      if (!fileResult.isSuccess) {
        return false;
      }
      
      final file = fileResult.data;
      return file != null && await file.exists() && await file.length() > 0;
    });
  }
  
  @override
  Future<ApiResult<void>> clearCachedPdf(String bookId) {
    return handleAsyncDataSourceCall(() async {
      final fileResult = await getCachedPdfFile(bookId);
      if (fileResult.isSuccess && fileResult.data != null) {
        final file = fileResult.data!;
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      final pdfCacheKey = 'PDF_CACHE_TIME_$bookId';
      await sharedPreferences.remove(pdfCacheKey);
    });
  }
}