import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:korean_language_app/core/errors/failures.dart';
import 'package:korean_language_app/core/network/network_info.dart';
import 'package:korean_language_app/features/admin/data/service/admin_permission.dart';
import 'package:korean_language_app/features/book_upload/data/datasources/book_upload_remote_datasource.dart';
import 'package:korean_language_app/features/book_upload/domain/repositories/book_upload_repository.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

class BookUploadRepositoryImpl implements BookUploadRepository {
  final BookUploadRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final AdminPermissionService adminService;

  BookUploadRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.adminService,
  });

  @override
  Future<Either<Failure, Map<String, dynamic>>> uploadPdfFile(String bookId, File pdfFile) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final result = await remoteDataSource.uploadPdfFile(bookId, pdfFile);
      if (result == null) {
        return const Left(ServerFailure('Failed to upload PDF file'));
      }
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Error uploading PDF: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> uploadCoverImage(String bookId, File imageFile) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final result = await remoteDataSource.uploadCoverImage(bookId, imageFile);
      if (result == null) {
        return const Left(ServerFailure('Failed to upload cover image'));
      }
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Error uploading image: $e'));
    }
  }

  @override
  Future<Either<Failure, BookItem>> createBook(BookItem book) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final success = await remoteDataSource.uploadBook(book);
      if (!success) {
        return const Left(ServerFailure('Failed to create book'));
      }
      
      final updatedBookList = await remoteDataSource.searchBookById(book.id);
      if (updatedBookList.isEmpty) {
        return Right(book);
      }
      
      return Right(updatedBookList.first);
    } catch (e) {
      return Left(ServerFailure('Error creating book: $e'));
    }
  }

  @override
  Future<Either<Failure, BookItem>> updateBook(String bookId, BookItem updatedBook) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final success = await remoteDataSource.updateBook(bookId, updatedBook);
      if (!success) {
        return const Left(ServerFailure('Failed to update book'));
      }
      
      final updatedBookList = await remoteDataSource.searchBookById(bookId);
      if (updatedBookList.isEmpty) {
        return Right(updatedBook);
      }
      
      return Right(updatedBookList.first);
    } catch (e) {
      return Left(ServerFailure('Error updating book: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteBook(String bookId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final success = await remoteDataSource.deleteBook(bookId);
      return Right(success);
    } catch (e) {
      return Left(ServerFailure('Error deleting book: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasEditPermission(String bookId, String userId) async {
    try {
      // Check if user is admin
      if (await adminService.isUserAdmin(userId)) {
        return const Right(true);
      }
      
      // Check if user is creator
      final book = await remoteDataSource.getBookById(bookId);
      if (book != null && book.creatorUid == userId) {
        return const Right(true);
      }
      
      return const Right(false);
    } catch (e) {
      return Left(ServerFailure('Error checking edit permission: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasDeletePermission(String bookId, String userId) async {
    // Typically the same permission check as edit
    return hasEditPermission(bookId, userId);
  }
}