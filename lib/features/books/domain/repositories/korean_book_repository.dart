import 'dart:io';

import 'package:korean_language_app/features/books/domain/repositories/book_repository.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

abstract class KoreanBookRepository extends BookRepository {
  Future<bool> deleteBookWithFiles(String bookId);
  Future<String?> uploadBookCoverImage(String bookId, File imageFile);
  Future<bool> uploadBookWithPdf(BookItem book, File pdfFile);
  Future<File?> getBookPdf(String bookId);
  Future<bool> updateBookMetadata(BookItem book);
  Future<String?> regenerateImageUrl(BookItem book);
}