import 'dart:convert';
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
  Future<ApiResult<List<BookItem>>> getCachedKoreanBooks() async {
    return handleDataSourceCall(() {
      final jsonString = sharedPreferences.getString(cacheKey);
      if (jsonString != null) {
        final List<dynamic> decodedJson = json.decode(jsonString);
        return decodedJson.map((item) => BookItem.fromJson(item)).toList();
      }
      return <BookItem>[];
    });
  }

  @override
  Future<ApiResult<void>> cacheKoreanBooks(List<BookItem> books) async {
    if (books.isEmpty) {
      return ApiResult.success(null);
    }
    
    return handleAsyncDataSourceCall(() async {
      final existingBooksResult = await getCachedKoreanBooks();
      final currentBooks = existingBooksResult.data ?? [];
      
      final Map<String, BookItem> uniqueBooks = {
        for (var book in currentBooks) book.id: book
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
  Future<ApiResult<bool>> hasAnyCachedBooks() async {
    return handleDataSourceCall(() {
      return sharedPreferences.containsKey(cacheKey);
    });
  }

  @override
  Future<ApiResult<int>> getCachedBooksCount() async {
    return handleAsyncDataSourceCall(() async {
      final result = await getCachedKoreanBooks();
      return result.data?.length ?? 0;
    });
  }

  @override
  Future<ApiResult<void>> clearCachedKoreanBooks() async {
    return handleAsyncDataSourceCall(() async {
      await sharedPreferences.remove(cacheKey);
      await sharedPreferences.remove(lastCacheTimeKey);
    });
  }
  
  @override
  Future<ApiResult<void>> updateBookMetadata(BookItem book) async {
    return handleAsyncDataSourceCall(() async {
      final existingBooksResult = await getCachedKoreanBooks();
      final existingBooks = existingBooksResult.data ?? [];
      
      final index = existingBooks.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        existingBooks[index] = book;
        
        final List<Map<String, dynamic>> jsonList = 
            existingBooks.map((book) => book.toJson()).toList();
        
        final String jsonString = json.encode(jsonList);
        await sharedPreferences.setString(cacheKey, jsonString);
      } else {
        await cacheKoreanBooks([book]);
      }
    });
  }
  
  @override
  Future<ApiResult<File?>> getCachedPdfFile(String bookId) async {
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
  Future<ApiResult<void>> cachePdfFile(String bookId, File pdfFile) async {
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
      }
    });
  }
  
  @override
  Future<ApiResult<bool>> hasCachedPdf(String bookId) async {
    return handleAsyncDataSourceCall(() async {
      final fileResult = await getCachedPdfFile(bookId);
      final file = fileResult.data;
      return file != null && await file.exists() && await file.length() > 0;
    });
  }
  
  @override
  Future<ApiResult<void>> clearCachedPdf(String bookId) async {
    return handleAsyncDataSourceCall(() async {
      final fileResult = await getCachedPdfFile(bookId);
      final file = fileResult.data;
      if (file != null && await file.exists()) {
        await file.delete();
      }
      
      final pdfCacheKey = 'PDF_CACHE_TIME_$bookId';
      await sharedPreferences.remove(pdfCacheKey);
    });
  }
}