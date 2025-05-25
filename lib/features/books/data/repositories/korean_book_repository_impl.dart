import 'dart:developer' as dev;
import 'dart:io';

import 'package:korean_language_app/core/enums/course_category.dart';
import 'package:korean_language_app/core/network/network_info.dart';
import 'package:korean_language_app/features/books/data/datasources/korean_books_local_datasource.dart';
import 'package:korean_language_app/features/books/data/datasources/korean_books_remote_data_source.dart';
import 'package:korean_language_app/features/books/domain/repositories/korean_book_repository.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';
import 'package:path_provider/path_provider.dart';

class KoreanBookRepositoryImpl implements KoreanBookRepository {
  final KoreanBooksRemoteDataSource remoteDataSource;
  final KoreanBooksLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final Duration cacheValidity;

  KoreanBookRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    this.cacheValidity = const Duration(minutes: 30),
  });

  @override
  Future<List<BookItem>> getBooks(CourseCategory category, {int page = 0, int pageSize = 5}) async {
    if (category != CourseCategory.korean) {
      return [];
    }

    if (page == 0) {
      final cachedBooks = await getBooksFromCache();
      if(cachedBooks.isNotEmpty) {
        return cachedBooks;
      }
    }

    final isConnected = await networkInfo.isConnected;
    if (isConnected) {
      try {
        final remoteBooks = await remoteDataSource.getKoreanBooks(page: page, pageSize: pageSize);
        await localDataSource.cacheKoreanBooks(remoteBooks);
        
        return remoteBooks;
      } catch (e) {
        dev.log('Error fetching page $page: $e');
        return [];
      }
    } else {
      final allCached = await getBooksFromCache();
      final start = page * pageSize;
      final end = start + pageSize < allCached.length ? start + pageSize : allCached.length;
      
      if (start >= allCached.length) {
        return [];
      }
      
      return allCached.sublist(start, end);
    }
  }

  @override
  Future<List<BookItem>> getBooksFromCache() async {
    return await localDataSource.getCachedKoreanBooks();
  }

  @override
  Future<bool> hasMoreBooks(CourseCategory category, int currentCount) async {
    if (category != CourseCategory.korean) {
      return false;
    }
    
    final isConnected = await networkInfo.isConnected;
    
    if (isConnected) {
      try {
        return await remoteDataSource.hasMoreBooks(currentCount);
      } catch (e) {
        dev.log('Error checking for more books: $e');
        final totalCachedCount = await localDataSource.getCachedBooksCount();
        return currentCount < totalCachedCount;
      }
    } else {
      final totalCachedCount = await localDataSource.getCachedBooksCount();
      return currentCount < totalCachedCount;
    }
  }

  @override
  Future<List<BookItem>> hardRefreshBooks(CourseCategory category, {int pageSize = 5}) async {
    if (category != CourseCategory.korean) {
      return [];
    }

    final isConnected = await networkInfo.isConnected;
    if (isConnected) {
      try {
        await clearCachedBooks();
        
        final remoteBooks = await remoteDataSource.getKoreanBooks(page: 0, pageSize: pageSize);
        await localDataSource.cacheKoreanBooks(remoteBooks);
        
        return remoteBooks;
      } catch (e) {
        dev.log('Error hard refreshing books: $e');
        return await localDataSource.getCachedKoreanBooks();
      }
    } else {
      return await getBooksFromCache();
    }
  }

  @override
  Future<List<BookItem>> searchBooks(CourseCategory category, String query) async {
    if (category != CourseCategory.korean) {
      return [];
    }

    final cachedResults = await searchInCache(query);
    
    final isConnected = await networkInfo.isConnected;
    if (cachedResults.isNotEmpty || !isConnected) {
      return cachedResults;
    }
    
    try {
      final remoteResults = await remoteDataSource.searchKoreanBooks(query);
      
      if (remoteResults.isNotEmpty) {
        await localDataSource.cacheKoreanBooks(remoteResults);
      }
      
      return remoteResults;
    } catch (e) {
      dev.log('Error searching books remotely: $e');
      return cachedResults;
    }
  }

  @override
  Future<void> clearCachedBooks() async {
    await localDataSource.clearCachedKoreanBooks();
  }

  Future<List<BookItem>> searchInCache(String query) async {
    final allCachedBooks = await getBooksFromCache();
    final normalizedQuery = query.toLowerCase();
    
    return allCachedBooks.where((book) {
      return book.title.toLowerCase().contains(normalizedQuery) ||
             book.description.toLowerCase().contains(normalizedQuery);
    }).toList();
  }
  
  @override
  Future<File?> getBookPdf(String bookId) async {
    dev.log('Getting PDF for bookId: $bookId');
    
    final cachedPdf = await localDataSource.getCachedPdfFile(bookId);
    
    if (cachedPdf != null && await cachedPdf.exists() && await cachedPdf.length() > 0) {
      dev.log('Using cached PDF file: ${cachedPdf.path}');
      return cachedPdf;
    }
    
    final isConnected = await networkInfo.isConnected;
    
    if (!isConnected) {
      throw Exception('No internet connection. Please try again when online.');
    }
    
    try {
      final books = await searchBooks(CourseCategory.korean, '');
      final book = books.firstWhere(
        (book) => book.id == bookId,
        orElse: () => throw Exception('Book not found')
      );
      
      String? pdfUrl = book.pdfUrl;
      bool urlWorking = false;
      
      // Try the existing URL first
      if (pdfUrl != null && pdfUrl.isNotEmpty) {
        dev.log('Attempting to use existing PDF URL: $pdfUrl');
        try {
          // Try to download a small portion to verify URL is working
          final result = await remoteDataSource.verifyUrlIsWorking(pdfUrl);
          urlWorking = result;
          dev.log('PDF URL check result: ${urlWorking ? "Valid" : "Invalid"}');
        } catch (e) {
          dev.log('PDF URL verification failed: $e');
          urlWorking = false;
        }
      }
      
      // If URL is missing or not working, try to regenerate it from path
      if ((!urlWorking || pdfUrl == null || pdfUrl.isEmpty) && 
          book.pdfPath != null && book.pdfPath!.isNotEmpty) {
        dev.log('PDF URL missing or invalid, attempting to regenerate from path: ${book.pdfPath}');
        pdfUrl = await remoteDataSource.regenerateUrlFromPath(book.pdfPath!);
        
        // If we successfully regenerated the URL, update the book
        if (pdfUrl != null && pdfUrl.isNotEmpty) {
          final updatedBook = BookItem(
            id: book.id,
            title: book.title,
            description: book.description,
            bookImage: book.bookImage,
            pdfUrl: pdfUrl,
            bookImagePath: book.bookImagePath,
            pdfPath: book.pdfPath,
            duration: book.duration,
            chaptersCount: book.chaptersCount,
            icon: book.icon,
            level: book.level,
            courseCategory: book.courseCategory,
            country: book.country,
            category: book.category,
          );
          
          await updateBookMetadata(updatedBook);
          dev.log('Successfully regenerated PDF URL and updated book');
          urlWorking = true;
        }
      }
      
      if (pdfUrl == null || pdfUrl.isEmpty || !urlWorking) {
        throw Exception('Book has no valid PDF URL and regeneration failed');
      }
      
      // Now download the PDF using the verified URL
      final directory = await getApplicationDocumentsDirectory();
      final tempPath = '${directory.path}/temp_${bookId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      final downloadedFile = await remoteDataSource.downloadPdfToLocal(bookId, tempPath);
      
      if (downloadedFile != null && await downloadedFile.exists() && await downloadedFile.length() > 0) {
        await localDataSource.cachePdfFile(bookId, downloadedFile);
        
        try {
          await downloadedFile.delete();
        } catch (e) {
          // Ignore error deleting temp file
        }
        
        return await localDataSource.getCachedPdfFile(bookId);
      }
    } catch (e) {
      dev.log('Error downloading PDF: $e');
      throw Exception('Failed to download PDF: ${e.toString().split(":").last.trim()}');
    }
    
    return null;
  }
  
  @override
  Future<bool> uploadBookWithPdf(BookItem book, File pdfFile) async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return false;
    }
    
    try {
      if (book.id.isEmpty) {
        throw Exception('Book ID cannot be empty');
      }
      
      final pdfUploadResult = await remoteDataSource.uploadPdfFile(book.id, pdfFile);
      
      if (pdfUploadResult != null) {
        final bookJson = book.toJson();
        bookJson['pdfUrl'] = pdfUploadResult['url'];
        bookJson['pdfPath'] = pdfUploadResult['storagePath'];
        final updatedBook = BookItem.fromJson(bookJson);
        
        final success = await remoteDataSource.uploadBook(updatedBook);
        
        if (success) {
          await localDataSource.cacheKoreanBooks([updatedBook]);
          await localDataSource.cachePdfFile(book.id, pdfFile);
          return true;
        }
      }
      
      return false;
    } catch (e) {
      dev.log('Error uploading book with PDF: $e');
      return false;
    }
  }

  @override
  Future<bool> updateBookMetadata(BookItem book) async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return false;
    }
    
    try {
      final success = await remoteDataSource.updateBook(book.id, book);
      
      if (success) {
        final cachedBooks = await localDataSource.getCachedKoreanBooks();
        final updatedBooks = [...cachedBooks];
        
        final index = updatedBooks.indexWhere((b) => b.id == book.id);
        if (index != -1) {
          updatedBooks[index] = book;
          await localDataSource.clearCachedKoreanBooks();
          await localDataSource.cacheKoreanBooks(updatedBooks);
        } else {
          await localDataSource.cacheKoreanBooks([book]);
        }
      }
      
      return success;
    } catch (e) {
      dev.log('Error updating book metadata: $e');
      return false;
    }
  }
  
  @override
  Future<String?> uploadBookCoverImage(String bookId, File imageFile) async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return null;
    }
    
    try {
      final imageUploadResult = await remoteDataSource.uploadCoverImage(bookId, imageFile);
      
      if (imageUploadResult != null) {
        final cachedBooks = await localDataSource.getCachedKoreanBooks();
        final bookIndex = cachedBooks.indexWhere((b) => b.id == bookId);
        
        if (bookIndex != -1) {
          final updatedBook = cachedBooks[bookIndex];
          final updatedBookData = updatedBook.toJson();
          updatedBookData['bookImage'] = imageUploadResult['url'];
          updatedBookData['bookImagePath'] = imageUploadResult['storagePath'];
          
          final book = BookItem.fromJson(updatedBookData);
          await localDataSource.updateBookMetadata(book);
          
          // Also update in Firestore
          await remoteDataSource.updateBook(bookId, book);
        }
        
        return imageUploadResult['url'];
      }
      
      return null;
    } catch (e) {
      dev.log('Error uploading cover image: $e');
      return null;
    }
  }
  
  // Add a method to regenerate and update image URLs
  @override
  Future<String?> regenerateImageUrl(BookItem book) async {
    if (book.bookImagePath == null || book.bookImagePath!.isEmpty) {
      return null;
    }
    
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return null;
    }
    
    try {
      // Attempt to regenerate the URL from the path
      final newUrl = await remoteDataSource.regenerateUrlFromPath(book.bookImagePath!);
      
      if (newUrl != null && newUrl.isNotEmpty) {
        // Create updated book with new URL
        final updatedBookData = book.toJson();
        updatedBookData['bookImage'] = newUrl;
        final updatedBook = BookItem.fromJson(updatedBookData);
        
        // Update metadata in both local storage and Firestore
        await localDataSource.updateBookMetadata(updatedBook);
        await remoteDataSource.updateBook(book.id, updatedBook);
        
        return newUrl;
      }
    } catch (e) {
      dev.log('Error regenerating image URL: $e');
    }
    
    return null;
  }
  
  @override
  Future<bool> deleteBookWithFiles(String bookId) async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return false;
    }
    
    try {
      final success = await remoteDataSource.deleteBook(bookId);
      
      if (success) {
        final cachedBooks = await localDataSource.getCachedKoreanBooks();
        final updatedBooks = cachedBooks.where((book) => book.id != bookId).toList();
        
        await localDataSource.clearCachedKoreanBooks();
        if (updatedBooks.isNotEmpty) {
          await localDataSource.cacheKoreanBooks(updatedBooks);
        }
        
        await localDataSource.clearCachedPdf(bookId);
        
        return true;
      }
      
      return false;
    } catch (e) {
      dev.log('Error deleting book with files: $e');
      return false;
    }
  }
}