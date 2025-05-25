import 'dart:io';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

abstract class KoreanBooksRemoteDataSource {
  Future<List<BookItem>> getKoreanBooks({int page = 0, int pageSize = 5});
  Future<bool> hasMoreBooks(int currentCount);
  Future<List<BookItem>> searchKoreanBooks(String query);
  Future<bool> uploadBook(BookItem book);
  Future<bool> updateBook(String bookId, BookItem updatedBook);
  Future<bool> deleteBook(String bookId);
  Future<Map<String, String>?> uploadPdfFile(String bookId, File pdfFile);
  Future<Map<String, String>?> uploadCoverImage(String bookId, File imageFile);
  Future<DateTime?> getBookLastUpdated(String bookId);
  Future<File?> downloadPdfToLocal(String bookId, String localPath);
  Future<String?> getPdfDownloadUrl(String bookId);
  Future<String?> regenerateUrlFromPath(String storagePath);
  Future<bool> verifyUrlIsWorking(String url);
}