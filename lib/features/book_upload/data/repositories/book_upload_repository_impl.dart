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
  Future<ApiResult<Map<String, dynamic>>> uploadPdfFile(String bookId, File pdfFile) async {
    return handleRepositoryCall(() async {
      try {
        final result = await remoteDataSource.uploadPdfFile(bookId, pdfFile);
        if (result == null) {
          return ApiResult.failure('Failed to upload PDF file', FailureType.server);
        }
        return ApiResult.success(result);
      } catch (e) {
        return ApiResult.failure('Error uploading PDF: $e', FailureType.server);
      }
    });
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> uploadCoverImage(String bookId, File imageFile) async {
    return handleRepositoryCall(() async {
      try {
        final result = await remoteDataSource.uploadCoverImage(bookId, imageFile);
        if (result == null) {
          return ApiResult.failure('Failed to upload cover image', FailureType.server);
        }
        return ApiResult.success(result);
      } catch (e) {
        return ApiResult.failure('Error uploading image: $e', FailureType.server);
      }
    });
  }

  @override
  Future<ApiResult<BookItem>> createBook(BookItem book) async {
    return handleRepositoryCall(() async {
      try {
        final success = await remoteDataSource.uploadBook(book);
        if (!success) {
          return ApiResult.failure('Failed to create book', FailureType.server);
        }
        
        final updatedBookList = await remoteDataSource.searchBookById(book.id);
        if (updatedBookList.isEmpty) {
          return ApiResult.success(book);
        }
        
        return ApiResult.success(updatedBookList.first);
      } catch (e) {
        return ApiResult.failure('Error creating book: $e', FailureType.server);
      }
    });
  }

  @override
  Future<ApiResult<BookItem>> updateBook(String bookId, BookItem updatedBook) async {
    return handleRepositoryCall(() async {
      try {
        final success = await remoteDataSource.updateBook(bookId, updatedBook);
        if (!success) {
          return ApiResult.failure('Failed to update book', FailureType.server);
        }
        
        final updatedBookList = await remoteDataSource.searchBookById(bookId);
        if (updatedBookList.isEmpty) {
          return ApiResult.success(updatedBook);
        }
        
        return ApiResult.success(updatedBookList.first);
      } catch (e) {
        return ApiResult.failure('Error updating book: $e', FailureType.server);
      }
    });
  }

  @override
  Future<ApiResult<bool>> deleteBook(String bookId) async {
    return handleRepositoryCall(() async {
      try {
        final success = await remoteDataSource.deleteBook(bookId);
        return ApiResult.success(success);
      } catch (e) {
        return ApiResult.failure('Error deleting book: $e', FailureType.server);
      }
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
      return ApiResult.failure('Error checking edit permission: $e', FailureType.server);
    }
  }

  @override
  Future<ApiResult<bool>> hasDeletePermission(String bookId, String userId) async {
    return hasEditPermission(bookId, userId);
  }
}