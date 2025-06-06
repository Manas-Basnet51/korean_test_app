import 'dart:io';

import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

abstract class BookUploadRepository {
  Future<ApiResult<Map<String, dynamic>>> uploadPdfFile(String bookId, File pdfFile);
  Future<ApiResult<Map<String, dynamic>>> uploadCoverImage(String bookId, File imageFile);
  Future<ApiResult<BookItem>> createBook(BookItem book);
  Future<ApiResult<BookItem>> updateBook(String bookId, BookItem updatedBook);
  Future<ApiResult<bool>> deleteBook(String bookId);
  Future<ApiResult<bool>> hasEditPermission(String bookId, String userId);
  Future<ApiResult<bool>> hasDeletePermission(String bookId, String userId);
}