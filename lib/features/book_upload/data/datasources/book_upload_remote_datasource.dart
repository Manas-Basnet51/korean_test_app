import 'dart:io';

import 'package:korean_language_app/features/books/data/models/book_item.dart';

abstract class BookUploadRemoteDataSource {
  Future<Map<String, String>?> uploadPdfFile(String bookId, File pdfFile);
  Future<Map<String, String>?> uploadCoverImage(String bookId, File imageFile);
  Future<bool> uploadBook(BookItem book);
  Future<bool> updateBook(String bookId, BookItem updatedBook);
  Future<bool> deleteBook(String bookId);
  Future<List<BookItem>> searchBookById(String bookId);
  Future<BookItem?> getBookById(String bookId);
}