import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:korean_language_app/core/errors/failures.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

abstract class BookUploadRepository {
  Future<Either<Failure, Map<String, dynamic>>> uploadPdfFile(String bookId, File pdfFile);
  Future<Either<Failure, Map<String, dynamic>>> uploadCoverImage(String bookId, File imageFile);
  Future<Either<Failure, BookItem>> createBook(BookItem book);
  Future<Either<Failure, BookItem>> updateBook(String bookId, BookItem updatedBook);
  Future<Either<Failure, bool>> deleteBook(String bookId);
  Future<Either<Failure, bool>> hasEditPermission(String bookId, String userId);
  Future<Either<Failure, bool>> hasDeletePermission(String bookId, String userId);
}