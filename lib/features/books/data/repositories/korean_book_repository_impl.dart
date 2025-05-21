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

    return handleRepositoryCall(
      () => remoteDataSource.getKoreanBooks(page: page, pageSize: pageSize),
      cacheCall: () async {
        final cachedBooks = await localDataSource.getCachedKoreanBooks();
        return cachedBooks.fold(
          onSuccess: (books) {
            final start = page * pageSize;
            final end = start + pageSize < books.length ? start + pageSize : books.length;
            
            if (start >= books.length) {
              return ApiResult.success([]);
            }
            
            return ApiResult.success(books.sublist(start, end));
          },
          onFailure: (msg, type) => ApiResult.failure(msg, type),
        );
      },
      cacheData: (books) async {
        final result = await localDataSource.cacheKoreanBooks(books);
        return result.fold(
          onSuccess: (_) {},
          onFailure: (msg, type) {
            // Log cache error but don't affect main flow
          },
        );
      },
    );
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
        return countResult.fold(
          onSuccess: (count) => ApiResult.success(currentCount < count),
          onFailure: (msg, type) => ApiResult.success(false),
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
        await localDataSource.clearCachedKoreanBooks();
        return remoteDataSource.getKoreanBooks(page: 0, pageSize: pageSize);
      },
      cacheData: (books) async {
        final result = await localDataSource.cacheKoreanBooks(books);
        return result.fold(
          onSuccess: (_) {},
          onFailure: (msg, type) {
            // Log cache error but don't affect main flow
          },
        );
      },
    );
  }

  @override
  Future<ApiResult<List<BookItem>>> getBooksFromCache() async {
    return localDataSource.getCachedKoreanBooks();
  }

  @override
  Future<ApiResult<List<BookItem>>> searchBooks(CourseCategory category, String query) async {
    if (category != CourseCategory.korean) {
      return ApiResult.success([]);
    }

    return handleRepositoryCall(
      () => remoteDataSource.searchKoreanBooks(query),
      cacheCall: () async {
        final cachedBooks = await localDataSource.getCachedKoreanBooks();
        return cachedBooks.fold(
          onSuccess: (books) {
            final normalizedQuery = query.toLowerCase();
            final filteredBooks = books.where((book) {
              return book.title.toLowerCase().contains(normalizedQuery) ||
                    book.description.toLowerCase().contains(normalizedQuery);
            }).toList();
            return ApiResult.success(filteredBooks);
          },
          onFailure: (msg, type) => ApiResult.failure(msg, type),
        );
      },
    );
  }

  @override
  Future<ApiResult<void>> clearCachedBooks() async {
    return localDataSource.clearCachedKoreanBooks();
  }

  @override
  Future<ApiResult<File?>> getBookPdf(String bookId) async {
    // First try to get from cache
    final cachedResult = await localDataSource.getCachedPdfFile(bookId);
    if (cachedResult.isSuccess && cachedResult.data != null) {
      return cachedResult;
    }

    // If not in cache, download from remote
    return handleRepositoryCall(
      () async {
        final urlResult = await remoteDataSource.getPdfDownloadUrl(bookId);
        return urlResult.fold(
          onSuccess: (url) async {
            if (url == null) {
              return ApiResult.failure('PDF URL not found', FailureType.notFound);
            }

            final directory = await getApplicationDocumentsDirectory();
            final tempPath = '${directory.path}/temp_${bookId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
            
            final downloadResult = await remoteDataSource.downloadPdfToLocal(bookId, tempPath);
            
            return downloadResult.fold(
              onSuccess: (file) async {
                if (file != null) {
                  await localDataSource.cachePdfFile(bookId, file);
                  return localDataSource.getCachedPdfFile(bookId);
                }
                return ApiResult.failure('Failed to download PDF');
              },
              onFailure: (msg, type) => ApiResult.failure(msg, type),
            );
          },
          onFailure: (msg, type) => ApiResult.failure(msg, type),
        );
      },
    );
  }

  @override
  Future<ApiResult<bool>> deleteBookWithFiles(String bookId) async {
    return handleRepositoryCall(
      () => remoteDataSource.deleteBook(bookId),
      cacheData: (success) async {
        if (success) {
          await localDataSource.clearCachedPdf(bookId);
          final cachedBooks = await localDataSource.getCachedKoreanBooks();
          return cachedBooks.fold(
            onSuccess: (books) async {
              final updatedBooks = books.where((book) => book.id != bookId).toList();
              await localDataSource.clearCachedKoreanBooks();
              if (updatedBooks.isNotEmpty) {
                await localDataSource.cacheKoreanBooks(updatedBooks);
              }
            },
            onFailure: (msg, type) {
              // Log cache error but don't affect main flow
            },
          );
        }
      },
    );
  }

  @override
  Future<ApiResult<String?>> uploadBookCoverImage(String bookId, File imageFile) async {
    return handleRepositoryCall(
      () async {
        final result = await remoteDataSource.uploadCoverImage(bookId, imageFile);
        return result.fold(
          onSuccess: (data) => ApiResult.success(data['url']),
          onFailure: (msg, type) => ApiResult.failure(msg, type),
        );
      },
    );
  }

  @override
  Future<ApiResult<bool>> uploadBookWithPdf(BookItem book, File pdfFile) async {
    return handleRepositoryCall(
      () async {
        final pdfResult = await remoteDataSource.uploadPdfFile(book.id, pdfFile);
        
        return pdfResult.fold(
          onSuccess: (pdfData) async {
            final updatedBook = book.copyWith(
              pdfUrl: pdfData['url'],
              pdfPath: pdfData['storagePath'],
            );
            
            return remoteDataSource.uploadBook(updatedBook);
          },
          onFailure: (msg, type) => ApiResult.failure(msg, type),
        );
      },
      cacheData: (success) async {
        if (success) {
          await localDataSource.cachePdfFile(book.id, pdfFile);
          await localDataSource.cacheKoreanBooks([book]);
        }
      },
    );
  }

  @override
  Future<ApiResult<bool>> updateBookMetadata(BookItem book) async {
    return handleRepositoryCall(
      () => remoteDataSource.updateBook(book.id, book),
      cacheData: (success) async {
        if (success) {
          await localDataSource.updateBookMetadata(book);
        }
      },
    );
  }

  @override
  Future<ApiResult<String?>> regenerateImageUrl(BookItem book) async {
    if (book.bookImagePath == null || book.bookImagePath!.isEmpty) {
      return ApiResult.success(null);
    }

    return handleRepositoryCall(
      () => remoteDataSource.regenerateUrlFromPath(book.bookImagePath!),
      cacheData: (newUrl) async {
        if (newUrl != null) {
          final updatedBook = book.copyWith(bookImage: newUrl);
          await localDataSource.updateBookMetadata(updatedBook);
        }
      },
    );
  }
}