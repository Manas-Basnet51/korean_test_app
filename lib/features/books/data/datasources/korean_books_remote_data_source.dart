import 'dart:io';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

abstract class KoreanBooksRemoteDataSource {
  Future<ApiResult<List<BookItem>>> getKoreanBooks({int page = 0, int pageSize = 5});
  Future<ApiResult<bool>> hasMoreBooks(int currentCount);
  Future<ApiResult<List<BookItem>>> searchKoreanBooks(String query);
  Future<ApiResult<bool>> uploadBook(BookItem book);
  Future<ApiResult<bool>> updateBook(String bookId, BookItem updatedBook);
  Future<ApiResult<bool>> deleteBook(String bookId);
  Future<ApiResult<Map<String, String>>> uploadPdfFile(String bookId, File pdfFile);
  Future<ApiResult<Map<String, String>>> uploadCoverImage(String bookId, File imageFile);
  Future<ApiResult<DateTime?>> getBookLastUpdated(String bookId);
  Future<ApiResult<File?>> downloadPdfToLocal(String bookId, String localPath);
  Future<ApiResult<String?>> getPdfDownloadUrl(String bookId);
  Future<ApiResult<String?>> regenerateUrlFromPath(String storagePath);
  Future<ApiResult<bool>> verifyUrlIsWorking(String url);
}

