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

  KoreanBookRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required NetworkInfo networkInfo,
  }) : super(networkInfo);

  @override
  Future<ApiResult<List<BookItem>>> getBooks(CourseCategory category, {int page = 0, int pageSize = 5}) async {
    if (category != CourseCategory.korean) {
      return ApiResult.success([]);
    }

    if (page == 0) {
      final cachedResult = await getBooksFromCache();
      if (cachedResult.isSuccess && cachedResult.data!.isNotEmpty) {
        return cachedResult;
      }
    }

    return handleRepositoryCall(
      () => remoteDataSource.getKoreanBooks(page: page, pageSize: pageSize),
      cacheCall: page == 0 ? () => getBooksFromCache() : null,
      cacheData: (books) async {
        final cacheResult = await localDataSource.cacheKoreanBooks(books);
        if (!cacheResult.isSuccess) {
          dev.log('Failed to cache books: ${cacheResult.error}');
        }
      },
    );
  }

  @override
  Future<ApiResult<List<BookItem>>> getBooksFromCache() {
    return localDataSource.getCachedKoreanBooks();
  }

  @override
  Future<ApiResult<bool>> hasMoreBooks(CourseCategory category, int currentCount) async {
    if (category != CourseCategory.korean) {
      return ApiResult.success(false);
    }
    
    return handleRepositoryCall(
      () => remoteDataSource.hasMoreBooks(currentCount),
      cacheCall: () async {
        final countResult = await localDataSource.getCachedBooksCount();
        if (countResult.isSuccess) {
          return ApiResult.success(currentCount < countResult.data!);
        }
        return countResult.fold(
          onSuccess: (_) => ApiResult.success(false),
          onFailure: (msg, type) => ApiResult.failure(msg, type),
        );
      },
    );
  }

  @override
  Future<ApiResult<List<BookItem>>> hardRefreshBooks(CourseCategory category, {int pageSize = 5}) async {
    if (category != CourseCategory.korean) {
      return ApiResult.success([]);
    }

    return handleRepositoryCall(
      () async {
        final clearResult = await clearCachedBooks();
        if (!clearResult.isSuccess) {
          dev.log('Failed to clear cache: ${clearResult.error}');
        }
        
        return await remoteDataSource.getKoreanBooks(page: 0, pageSize: pageSize);
      },
      cacheCall: () => localDataSource.getCachedKoreanBooks(),
      cacheData: (books) async {
        final cacheResult = await localDataSource.cacheKoreanBooks(books);
        if (!cacheResult.isSuccess) {
          dev.log('Failed to cache books: ${cacheResult.error}');
        }
      },
    );
  }

  @override
  Future<ApiResult<List<BookItem>>> searchBooks(CourseCategory category, String query) async {
    if (category != CourseCategory.korean) {
      return ApiResult.success([]);
    }

    final cachedResults = await _searchInCache(query);
    
    return handleRepositoryCall(
      () => remoteDataSource.searchKoreanBooks(query),
      cacheCall: () async => cachedResults,
      cacheData: (books) async {
        if (books.isNotEmpty) {
          final cacheResult = await localDataSource.cacheKoreanBooks(books);
          if (!cacheResult.isSuccess) {
            dev.log('Failed to cache search results: ${cacheResult.error}');
          }
        }
      },
    );
  }

  @override
  Future<ApiResult<void>> clearCachedBooks() {
    return localDataSource.clearCachedKoreanBooks();
  }

  Future<ApiResult<List<BookItem>>> _searchInCache(String query) async {
    final allCachedBooksResult = await getBooksFromCache();
    if (!allCachedBooksResult.isSuccess) {
      return allCachedBooksResult;
    }
    
    final allCachedBooks = allCachedBooksResult.data!;
    final normalizedQuery = query.toLowerCase();
    
    final results = allCachedBooks.where((book) {
      return book.title.toLowerCase().contains(normalizedQuery) ||
             book.description.toLowerCase().contains(normalizedQuery);
    }).toList();
    
    return ApiResult.success(results);
  }
  
  @override
  Future<ApiResult<File?>> getBookPdf(String bookId) async {
    dev.log('Getting PDF for bookId: $bookId');
    
    final cachedPdfResult = await localDataSource.getCachedPdfFile(bookId);
    if (cachedPdfResult.isSuccess && cachedPdfResult.data != null) {
      final cachedPdf = cachedPdfResult.data!;
      if (await cachedPdf.exists() && await cachedPdf.length() > 0) {
        dev.log('Using cached PDF file: ${cachedPdf.path}');
        return ApiResult.success(cachedPdf);
      }
    }
    
    return handleRepositoryCall(
      () async {
        final searchResult = await searchBooks(CourseCategory.korean, '');
        if (!searchResult.isSuccess) {
          throw Exception('Failed to search books: ${searchResult.error}');
        }
        
        final books = searchResult.data!;
        final book = books.firstWhere(
          (book) => book.id == bookId,
          orElse: () => throw Exception('Book not found')
        );
        
        String? pdfUrl = book.pdfUrl;
        bool urlWorking = false;
        
        if (pdfUrl != null && pdfUrl.isNotEmpty) {
          dev.log('Attempting to use existing PDF URL: $pdfUrl');
          final verifyResult = await remoteDataSource.verifyUrlIsWorking(pdfUrl);
          if (verifyResult.isSuccess) {
            urlWorking = verifyResult.data ?? false;
            dev.log('PDF URL check result: ${urlWorking ? "Valid" : "Invalid"}');
          }
        }
        
        if ((!urlWorking || pdfUrl == null || pdfUrl.isEmpty) && 
            book.pdfPath != null && book.pdfPath!.isNotEmpty) {
          dev.log('PDF URL missing or invalid, attempting to regenerate from path: ${book.pdfPath}');
          final regenerateResult = await remoteDataSource.regenerateUrlFromPath(book.pdfPath!);
          
          if (regenerateResult.isSuccess && regenerateResult.data != null && regenerateResult.data!.isNotEmpty) {
            pdfUrl = regenerateResult.data!;
            
            final updatedBook = BookItem(
              id: book.id,
              title: book.title,
              description: book.description,
              bookImage: book.bookImage,
              pdfUrl: pdfUrl,
              bookImagePath: book.bookImagePath,
              pdfPath: book.pdfPath,
              duration: book.duration,
              chaptersCount: book.chaptersCount,
              icon: book.icon,
              level: book.level,
              courseCategory: book.courseCategory,
              country: book.country,
              category: book.category,
            );
            
            final updateResult = await updateBookMetadata(updatedBook);
            if (updateResult.isSuccess) {
              dev.log('Successfully regenerated PDF URL and updated book');
              urlWorking = true;
            }
          }
        }
        
        if (pdfUrl == null || pdfUrl.isEmpty || !urlWorking) {
          throw Exception('Book has no valid PDF URL and regeneration failed');
        }
        
        final directory = await getApplicationDocumentsDirectory();
        final tempPath = '${directory.path}/temp_${bookId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        
        final downloadResult = await remoteDataSource.downloadPdfToLocal(bookId, tempPath);
        if (!downloadResult.isSuccess) {
          throw Exception('Failed to download PDF: ${downloadResult.error}');
        }
        
        final downloadedFile = downloadResult.data;
        if (downloadedFile != null && await downloadedFile.exists() && await downloadedFile.length() > 0) {
          final cacheResult = await localDataSource.cachePdfFile(bookId, downloadedFile);
          if (!cacheResult.isSuccess) {
            dev.log('Failed to cache PDF: ${cacheResult.error}');
          }
          
          try {
            await downloadedFile.delete();
          } catch (e) {
            // Ignore error deleting temp file
          }
          
          final finalResult = await localDataSource.getCachedPdfFile(bookId);
          if (finalResult.isSuccess) {
            return ApiResult.success(finalResult.data);
          } else {
            return ApiResult.failure('Failed to get cached PDF file: ${finalResult.error}');
          }
        }
        
        return ApiResult.success(null);
      },
    );
  }
  
  @override
  Future<ApiResult<bool>> uploadBookWithPdf(BookItem book, File pdfFile) {
    return handleRepositoryCall(
      () async {
        if (book.id.isEmpty) {
          throw Exception('Book ID cannot be empty');
        }
        
        final pdfUploadResult = await remoteDataSource.uploadPdfFile(book.id, pdfFile);
        if (!pdfUploadResult.isSuccess) {
          throw Exception('Failed to upload PDF: ${pdfUploadResult.error}');
        }
        
        final uploadData = pdfUploadResult.data!;
        final bookJson = book.toJson();
        bookJson['pdfUrl'] = uploadData.$1;
        bookJson['pdfPath'] = uploadData.$2;
        final updatedBook = BookItem.fromJson(bookJson);
        
        final bookUploadResult = await remoteDataSource.uploadBook(updatedBook);
        if (!bookUploadResult.isSuccess) {
          throw Exception('Failed to upload book: ${bookUploadResult.error}');
        }
        
        final cacheBookResult = await localDataSource.cacheKoreanBooks([updatedBook]);
        if (!cacheBookResult.isSuccess) {
          dev.log('Failed to cache book: ${cacheBookResult.error}');
        }
        
        final cachePdfResult = await localDataSource.cachePdfFile(book.id, pdfFile);
        if (!cachePdfResult.isSuccess) {
          dev.log('Failed to cache PDF: ${cachePdfResult.error}');
        }
        
        return ApiResult.success(bookUploadResult.data!);
      },
    );
  }

  @override
  Future<ApiResult<bool>> updateBookMetadata(BookItem book) {
    return handleRepositoryCall(
      () async {
        final result = await remoteDataSource.updateBook(book.id, book);
        if (!result.isSuccess) {
          throw Exception('Failed to update book: ${result.error}');
        }
        
        final updateLocalResult = await localDataSource.updateBookMetadata(book);
        if (!updateLocalResult.isSuccess) {
          dev.log('Failed to update local book metadata: ${updateLocalResult.error}');
        }
        
        return ApiResult.success(result.data!);
      },
    );
  }
  
  @override
  Future<ApiResult<String?>> uploadBookCoverImage(String bookId, File imageFile) {
    return handleRepositoryCall(
      () async {
        final imageUploadResult = await remoteDataSource.uploadCoverImage(bookId, imageFile);
        if (!imageUploadResult.isSuccess) {
          throw Exception('Failed to upload cover image: ${imageUploadResult.error}');
        }
        
        final uploadData = imageUploadResult.data!;
        final cachedBooksResult = await localDataSource.getCachedKoreanBooks();
        
        if (cachedBooksResult.isSuccess) {
          final cachedBooks = cachedBooksResult.data!;
          final bookIndex = cachedBooks.indexWhere((b) => b.id == bookId);
          
          if (bookIndex != -1) {
            final updatedBook = cachedBooks[bookIndex];
            final updatedBookData = updatedBook.toJson();
            updatedBookData['bookImage'] = uploadData.$1;
            updatedBookData['bookImagePath'] = uploadData.$2;
            
            final book = BookItem.fromJson(updatedBookData);
            final updateLocalResult = await localDataSource.updateBookMetadata(book);
            if (!updateLocalResult.isSuccess) {
              dev.log('Failed to update local book metadata: ${updateLocalResult.error}');
            }
            
            final updateRemoteResult = await remoteDataSource.updateBook(bookId, book);
            if (!updateRemoteResult.isSuccess) {
              dev.log('Failed to update remote book: ${updateRemoteResult.error}');
            }
          }
        }
        
        return ApiResult.success(uploadData.$1);
      },
    );
  }
  
  @override
  Future<ApiResult<String?>> regenerateImageUrl(BookItem book) async {
    if (book.bookImagePath == null || book.bookImagePath!.isEmpty) {
      return ApiResult.success(null);
    }
    
    return handleRepositoryCall(
      () async {
        final regenerateResult = await remoteDataSource.regenerateUrlFromPath(book.bookImagePath!);
        if (!regenerateResult.isSuccess || regenerateResult.data == null || regenerateResult.data!.isEmpty) {
          return ApiResult.success(null);
        }
        
        final newUrl = regenerateResult.data!;
        final updatedBookData = book.toJson();
        updatedBookData['bookImage'] = newUrl;
        final updatedBook = BookItem.fromJson(updatedBookData);
        
        final updateLocalResult = await localDataSource.updateBookMetadata(updatedBook);
        if (!updateLocalResult.isSuccess) {
          dev.log('Failed to update local book metadata: ${updateLocalResult.error}');
        }
        
        final updateRemoteResult = await remoteDataSource.updateBook(book.id, updatedBook);
        if (!updateRemoteResult.isSuccess) {
          dev.log('Failed to update remote book: ${updateRemoteResult.error}');
        }
        
        return ApiResult.success(newUrl);
      },
    );
  }
  
  @override
  Future<ApiResult<bool>> deleteBookWithFiles(String bookId) {
    return handleRepositoryCall(
      () async {
        final deleteResult = await remoteDataSource.deleteBook(bookId);
        if (!deleteResult.isSuccess) {
          throw Exception('Failed to delete book: ${deleteResult.error}');
        }
        
        final cachedBooksResult = await localDataSource.getCachedKoreanBooks();
        if (cachedBooksResult.isSuccess) {
          final cachedBooks = cachedBooksResult.data!;
          final updatedBooks = cachedBooks.where((book) => book.id != bookId).toList();
          
          final clearResult = await localDataSource.clearCachedKoreanBooks();
          if (!clearResult.isSuccess) {
            dev.log('Failed to clear cached books: ${clearResult.error}');
          }
          
          if (updatedBooks.isNotEmpty) {
            final cacheResult = await localDataSource.cacheKoreanBooks(updatedBooks);
            if (!cacheResult.isSuccess) {
              dev.log('Failed to cache updated books: ${cacheResult.error}');
            }
          }
        }
        
        final clearPdfResult = await localDataSource.clearCachedPdf(bookId);
        if (!clearPdfResult.isSuccess) {
          dev.log('Failed to clear cached PDF: ${clearPdfResult.error}');
        }
        
        return ApiResult.success(deleteResult.data!);
      },
    );
  }
}

  