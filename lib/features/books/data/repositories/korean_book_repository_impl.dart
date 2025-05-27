import 'dart:developer' as dev;
import 'dart:io';
import 'package:korean_language_app/core/data/base_repository.dart';
import 'package:korean_language_app/core/enums/course_category.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/core/network/network_info.dart';
import 'package:korean_language_app/features/books/data/datasources/korean_books_local_datasource.dart';
import 'package:korean_language_app/features/books/data/datasources/korean_books_remote_data_source.dart';
import 'package:korean_language_app/features/books/domain/repositories/korean_book_repository.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';
import 'package:path_provider/path_provider.dart';

class KoreanBookRepositoryImpl extends BaseRepository implements KoreanBookRepository {
  final KoreanBooksRemoteDataSource remoteDataSource;
  final KoreanBooksLocalDataSource localDataSource;
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(seconds: 1);

  KoreanBookRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required NetworkInfo networkInfo,
  }) : super(networkInfo);

  @override
  Future<ApiResult<List<BookItem>>> getBooks(
    CourseCategory category, {
    int page = 0,
    int pageSize = 5,
  }) async {
    if (category != CourseCategory.korean) {
      return ApiResult.success([]);
    }

    return _executeWithRetry(() async {
      // For pagination beyond first page, always fetching from remote
      if (page > 0) {
        if (!await networkInfo.isConnected) {
          throw Exception('No internet connection for pagination');
        }
        return await remoteDataSource.getKoreanBooks(page: page, pageSize: pageSize);
      }

      // Check cache validity for first page
      if (await localDataSource.isCacheValid()) {
        final cachedBooks = await localDataSource.getCachedKoreanBooks();
        if (cachedBooks.isNotEmpty) {
          return cachedBooks;
        }
      }

      // Fetch from remote and cache
      return await _fetchAndCacheBooks(pageSize: pageSize);
    });
  }

  @override
  Future<ApiResult<List<BookItem>>> getBooksFromCache() async {
    try {
      final books = await localDataSource.getCachedKoreanBooks();
      return ApiResult.success(books);
    } catch (e) {
      return ApiResult.failure('Failed to get cached books: $e', FailureType.cache);
    }
  }

  @override
  Future<ApiResult<bool>> hasMoreBooks(CourseCategory category, int currentCount) async {
    if (category != CourseCategory.korean) {
      return ApiResult.success(false);
    }
    
    if (!await networkInfo.isConnected) {
      try {
        final totalCached = await localDataSource.getCachedBooksCount();
        return ApiResult.success(currentCount < totalCached);
      } catch (e) {
        return ApiResult.success(false);
      }
    }

    return _executeWithRetry(() async {
      return await remoteDataSource.hasMoreBooks(currentCount);
    });
  }

  @override
  Future<ApiResult<List<BookItem>>> hardRefreshBooks(
    CourseCategory category, {
    int pageSize = 5,
  }) async {
    if (category != CourseCategory.korean) {
      return ApiResult.success([]);
    }

    return _executeWithRetry(() async {
      // Clear cache first
      await localDataSource.clearCachedKoreanBooks();
      
      // Fetch fresh data
      return await _fetchAndCacheBooks(pageSize: pageSize);
    });
  }

  @override
  Future<ApiResult<List<BookItem>>> searchBooks(CourseCategory category, String query) async {
    if (category != CourseCategory.korean || query.trim().length < 2) {
      return ApiResult.success([]);
    }

    try {
      // Always search in cache first for better UX
      final cachedBooks = await localDataSource.getCachedKoreanBooks();
      final cachedResults = _searchInCache(cachedBooks, query);
      
      if (!await networkInfo.isConnected) {
        return ApiResult.success(cachedResults);
      }

      // Search remotely with retry
      return await _executeWithRetry(() async {
        final remoteResults = await remoteDataSource.searchKoreanBooks(query);
        
        // Cache new search results
        if (remoteResults.isNotEmpty) {
          await localDataSource.cacheKoreanBooks(remoteResults);
        }
        
        // Combine and deduplicate results
        final combinedResults = _combineAndDeduplicateResults(cachedResults, remoteResults);
        return combinedResults;
      });
      
    } catch (e) {
      // Return cached results if remote search fails
      try {
        final cachedBooks = await localDataSource.getCachedKoreanBooks();
        final cachedResults = _searchInCache(cachedBooks, query);
        return ApiResult.success(cachedResults);
      } catch (cacheError) {
        return _mapExceptionToApiResult(e as Exception);
      }
    }
  }

  @override
  Future<ApiResult<void>> clearCachedBooks() async {
    try {
      await localDataSource.clearCachedKoreanBooks();
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure('Failed to clear cache: $e', FailureType.cache);
    }
  }

  @override
  Future<ApiResult<File?>> getBookPdf(String bookId) async {
    try {
      // Check cached PDF first with validation
      final cachedPdf = await localDataSource.getCachedPdfFile(bookId);
      if (cachedPdf != null && await _isValidPDF(cachedPdf)) {
        return ApiResult.success(cachedPdf);
      }

      if (!await networkInfo.isConnected) {
        return ApiResult.failure('No internet connection and no valid cached PDF', FailureType.network);
      }

      // Download and cache PDF with retry
      return await _executeWithRetry(() async {
        return await _downloadAndCachePdf(bookId);
      });
      
    } catch (e) {
      return _mapExceptionToApiResult(e as Exception);
    }
  }

  @override
  Future<ApiResult<bool>> updateBookMetadata(BookItem book) async {
    if (!await networkInfo.isConnected) {
      return ApiResult.failure('No internet connection', FailureType.network);
    }

    return _executeWithRetry(() async {
      final success = await remoteDataSource.updateBook(book.id, book);
      
      if (success) {
        try {
          await localDataSource.updateBookMetadata(book);
        } catch (e) {
          dev.log('Failed to update local cache: $e');
        }
      }
      
      return success;
    });
  }

  @override
  Future<ApiResult<bool>> deleteBookWithFiles(String bookId) async {
    if (!await networkInfo.isConnected) {
      return ApiResult.failure('No internet connection', FailureType.network);
    }

    return _executeWithRetry(() async {
      final success = await remoteDataSource.deleteBook(bookId);
      
      if (success) {
        try {
          await localDataSource.removeBookFromCache(bookId);
          await localDataSource.clearCachedPdf(bookId);
        } catch (e) {
          dev.log('Failed to remove from cache: $e');
        }
      }
      
      return success;
    });
  }

  @override
  Future<ApiResult<bool>> uploadBookWithPdf(BookItem book, File pdfFile) async {
    if (!await networkInfo.isConnected) {
      return ApiResult.failure('No internet connection', FailureType.network);
    }

    if (book.id.isEmpty) {
      return ApiResult.failure('Book ID cannot be empty', FailureType.validation);
    }

    return _executeWithRetry(() async {
      // Upload PDF first
      final pdfUploadData = await remoteDataSource.uploadPdfFile(book.id, pdfFile);
      
      // Update book with PDF info and upload
      final updatedBook = book.copyWith(
        pdfUrl: pdfUploadData.$1,
        pdfPath: pdfUploadData.$2,
      );

      final success = await remoteDataSource.uploadBook(updatedBook);
      
      if (success) {
        try {
          await localDataSource.cacheKoreanBooks([updatedBook]);
          await localDataSource.cachePdfFile(book.id, pdfFile);
        } catch (e) {
          dev.log('Failed to cache after upload: $e');
        }
      }
      
      return success;
    });
  }

  @override
  Future<ApiResult<String?>> uploadBookCoverImage(String bookId, File imageFile) async {
    if (!await networkInfo.isConnected) {
      return ApiResult.failure('No internet connection', FailureType.network);
    }

    return _executeWithRetry(() async {
      final uploadData = await remoteDataSource.uploadCoverImage(bookId, imageFile);
      final imageUrl = uploadData.$1;
      final imagePath = uploadData.$2;
      
      // Update book in cache with new image URL
      try {
        await _updateBookImageInCache(bookId, imageUrl, imagePath);
      } catch (e) {
        dev.log('Failed to update cache with new image: $e');
      }
      
      return imageUrl;
    });
  }

  @override
  Future<ApiResult<String?>> regenerateImageUrl(BookItem book) async {
    if (book.bookImagePath == null || book.bookImagePath!.isEmpty) {
      return ApiResult.success(null);
    }

    if (!await networkInfo.isConnected) {
      return ApiResult.failure('No internet connection', FailureType.network);
    }

    return _executeWithRetry(() async {
      final newUrl = await remoteDataSource.regenerateUrlFromPath(book.bookImagePath!);
      
      if (newUrl != null && newUrl.isNotEmpty) {
        final updatedBook = book.copyWith(bookImage: newUrl);
        
        try {
          await localDataSource.updateBookMetadata(updatedBook);
          await remoteDataSource.updateBook(book.id, updatedBook);
        } catch (e) {
          dev.log('Failed to update book with new image URL: $e');
        }
      }
      
      return newUrl;
    });
  }

  // Private helper methods
  Future<ApiResult<T>> _executeWithRetry<T>(Future<T> Function() operation) async {
    Exception? lastException;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final result = await operation();
        return ApiResult.success(result);
      } catch (e) {
        lastException = e as Exception;
        
        if (attempt == maxRetries) {
          break;
        }
        
        // Exponential backoff
        final delay = Duration(seconds: initialRetryDelay.inSeconds * attempt);
        await Future.delayed(delay);
        
        dev.log('Retry attempt $attempt failed: $e. Retrying in ${delay.inSeconds}s...');
      }
    }
    
    return _mapExceptionToApiResult(lastException!);
  }

  Future<List<BookItem>> _fetchAndCacheBooks({required int pageSize}) async {
    if (!await networkInfo.isConnected) {
      // Try to return cached data as fallback
      final cachedBooks = await localDataSource.getCachedKoreanBooks();
      if (cachedBooks.isNotEmpty) {
        return cachedBooks;
      }
      throw Exception('No internet connection and no cached data');
    }

    final remoteBooks = await remoteDataSource.getKoreanBooks(page: 0, pageSize: pageSize);
    
    // Detect deleted books for cache sync
    final deletedIds = await localDataSource.getDeletedBookIds(remoteBooks);
    for (final deletedId in deletedIds) {
      await localDataSource.removeBookFromCache(deletedId);
    }
    
    // Cache new/updated books
    await localDataSource.cacheKoreanBooks(remoteBooks);
    
    return remoteBooks;
  }

  List<BookItem> _searchInCache(List<BookItem> books, String query) {
    final normalizedQuery = query.toLowerCase();
    
    return books.where((book) {
      return book.title.toLowerCase().contains(normalizedQuery) ||
             book.description.toLowerCase().contains(normalizedQuery) ||
             book.category.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  List<BookItem> _combineAndDeduplicateResults(
    List<BookItem> cachedBooks,
    List<BookItem> remoteBooks,
  ) {
    final Map<String, BookItem> uniqueBooks = {};
    
    // Add cached books first
    for (final book in cachedBooks) {
      uniqueBooks[book.id] = book;
    }
    
    // Add remote books (will override cached if same ID)
    for (final book in remoteBooks) {
      uniqueBooks[book.id] = book;
    }
    
    return uniqueBooks.values.toList();
  }

  Future<File?> _downloadAndCachePdf(String bookId) async {
    try {
      // Get PDF URL from remote
      final pdfUrl = await remoteDataSource.getPdfDownloadUrl(bookId);
      if (pdfUrl == null || pdfUrl.isEmpty) {
        throw Exception('PDF URL not found for book');
      }

      // Create temp file for download
      final directory = await getApplicationDocumentsDirectory();
      final tempPath = '${directory.path}/temp_${bookId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // Download PDF
      final downloadedFile = await remoteDataSource.downloadPdfToLocal(bookId, tempPath);
      if (downloadedFile == null) {
        throw Exception('Failed to download PDF');
      }

      // Verify downloaded file
      if (!await downloadedFile.exists() || await downloadedFile.length() == 0) {
        throw Exception('Downloaded PDF is invalid');
      }

      if (!await _isValidPDF(downloadedFile)) {
        throw Exception('Downloaded file is not a valid PDF');
      }

      // Cache the PDF
      try {
        await localDataSource.cachePdfFile(bookId, downloadedFile);
      } catch (e) {
        dev.log('Failed to cache PDF: $e');
      }

      // Clean up temp file
      try {
        await downloadedFile.delete();
      } catch (e) {
        dev.log('Failed to delete temp file: $e');
      }

      // Return cached PDF
      return await localDataSource.getCachedPdfFile(bookId);
    } catch (e) {
      throw Exception('Error downloading PDF: $e');
    }
  }

  Future<void> _updateBookImageInCache(String bookId, String imageUrl, String imagePath) async {
    try {
      final cachedBooks = await localDataSource.getCachedKoreanBooks();
      final bookIndex = cachedBooks.indexWhere((b) => b.id == bookId);
      
      if (bookIndex != -1) {
        final updatedBook = cachedBooks[bookIndex].copyWith(
          bookImage: imageUrl,
          bookImagePath: imagePath,
        );
        
        await localDataSource.updateBookMetadata(updatedBook);
        await remoteDataSource.updateBook(bookId, updatedBook);
      }
    } catch (e) {
      dev.log('Error updating book image in cache: $e');
    }
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

  ApiResult<T> _mapExceptionToApiResult<T>(Exception e) {
    final message = e.toString();
    
    if (message.contains('Permission denied')) {
      return ApiResult.failure(message, FailureType.permission);
    } else if (message.contains('not found') || message.contains('Resource not found')) {
      return ApiResult.failure(message, FailureType.notFound);
    } else if (message.contains('Authentication required')) {
      return ApiResult.failure(message, FailureType.auth);
    } else if (message.contains('Service unavailable') || message.contains('Server error')) {
      return ApiResult.failure(message, FailureType.server);
    } else if (message.contains('No internet connection')) {
      return ApiResult.failure(message, FailureType.network);
    } else if (message.contains('validation') || message.contains('cannot be empty')) {
      return ApiResult.failure(message, FailureType.validation);
    } else {
      return ApiResult.failure(message, FailureType.unknown);
    }
  }
}