import 'dart:io';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

abstract class KoreanBooksLocalDataSource {
  Future<ApiResult<List<BookItem>>> getCachedKoreanBooks();
  Future<ApiResult<void>> cacheKoreanBooks(List<BookItem> books);
  Future<ApiResult<bool>> hasAnyCachedBooks();
  Future<ApiResult<int>> getCachedBooksCount();
  Future<ApiResult<void>> clearCachedKoreanBooks();
  
  Future<ApiResult<File?>> getCachedPdfFile(String bookId);
  Future<ApiResult<void>> cachePdfFile(String bookId, File pdfFile);
  Future<ApiResult<bool>> hasCachedPdf(String bookId);
  Future<ApiResult<void>> clearCachedPdf(String bookId);
  Future<ApiResult<void>> updateBookMetadata(BookItem book);
}