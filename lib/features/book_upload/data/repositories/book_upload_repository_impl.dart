import 'dart:io';

import 'package:korean_language_app/core/data/base_repository.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/core/network/network_info.dart';
import 'package:korean_language_app/features/admin/data/service/admin_permission.dart';
import 'package:korean_language_app/features/book_upload/data/datasources/book_upload_remote_datasource.dart';
import 'package:korean_language_app/features/book_upload/domain/repositories/book_upload_repository.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

class BookUploadRepositoryImpl extends BaseRepository implements BookUploadRepository {
  final BookUploadRemoteDataSource remoteDataSource;
  final AdminPermissionService adminService;

  BookUploadRepositoryImpl({
    required this.remoteDataSource,
    required NetworkInfo networkInfo,
    required this.adminService,
  }) : super(networkInfo);

  @override
  Future<ApiResult<BookItem>> createBook(BookItem book, File pdfFile, {File? coverImageFile}) async {
    return handleRepositoryCall(() async {
      final createdBook = await remoteDataSource.uploadBook(book, pdfFile, coverImageFile: coverImageFile);
      return ApiResult.success(createdBook);
    });
  }

  @override
  Future<ApiResult<BookItem>> updateBook(String bookId, BookItem updatedBook, {File? pdfFile, File? coverImageFile}) async {
    return handleRepositoryCall(() async {
      final updatedBookResult = await remoteDataSource.updateBook(bookId, updatedBook, pdfFile: pdfFile, coverImageFile: coverImageFile);
      return ApiResult.success(updatedBookResult);
    });
  }

  @override
  Future<ApiResult<bool>> deleteBook(String bookId) async {
    return handleRepositoryCall(() async {
      final success = await remoteDataSource.deleteBook(bookId);
      if (!success) {
        throw Exception('Failed to delete book');
      }
      return ApiResult.success(true);
    });
  }

  @override
  Future<ApiResult<bool>> hasEditPermission(String bookId, String userId) async {
    try {
      if (await adminService.isUserAdmin(userId)) {
        return ApiResult.success(true);
      }
      
      final book = await remoteDataSource.getBookById(bookId);
      if (book != null && book.creatorUid == userId) {
        return ApiResult.success(true);
      }
      
      return ApiResult.success(false);
    } catch (e) {
      return ApiResult.failure('Error checking edit permission: $e');
    }
  }

  @override
  Future<ApiResult<bool>> hasDeletePermission(String bookId, String userId) async {
    return hasEditPermission(bookId, userId);
  }
}