import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:korean_language_app/features/books/data/datasources/korean_books_remote_data_source.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

class FirestoreKoreanBooksDataSource implements KoreanBooksRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final String booksCollection = 'korean_books';
  
  DocumentSnapshot? _lastDocument;
  int? _totalBooksCount;
  DateTime? _lastCountFetch;

  FirestoreKoreanBooksDataSource({
    required this.firestore,
    required this.storage,
  });

  @override
  Future<List<BookItem>> getKoreanBooks({int page = 0, int pageSize = 5}) async {
    try {
      if (page == 0) {
        _lastDocument = null;
      }

      Query query = firestore.collection(booksCollection)
          .orderBy('title')
          .limit(pageSize);
      
      if (page > 0 && _lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }
      
      final querySnapshot = await query.get();
      final docs = querySnapshot.docs;
      
      if (docs.isNotEmpty) {
        _lastDocument = docs.last;
      }
      
      if (page == 0) {
        _updateTotalBooksCount(docs.length, isExact: false);
      }
      
      return docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; 
        return BookItem.fromJson(data);
      }).toList();
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to fetch books: $e');
    }
  }

  @override
  Future<bool> hasMoreBooks(int currentCount) async {
    try {
      if (_totalBooksCount != null && 
          _lastCountFetch != null &&
          DateTime.now().difference(_lastCountFetch!).inMinutes < 5) {
        return currentCount < _totalBooksCount!;
      }
      
      final countQuery = await firestore.collection(booksCollection).count().get();
      _updateTotalBooksCount(countQuery.count!, isExact: true);
      
      return currentCount < _totalBooksCount!;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to check for more books: $e');
    }
  }

  @override
  Future<List<BookItem>> searchKoreanBooks(String query) async {
    try {
      final normalizedQuery = query.toLowerCase();
      
      final titleQuery = firestore.collection(booksCollection)
          .where('titleLowerCase', isGreaterThanOrEqualTo: normalizedQuery)
          .where('titleLowerCase', isLessThanOrEqualTo: '$normalizedQuery\uf8ff')
          .limit(10);
      
      final titleSnapshot = await titleQuery.get();
      final List<BookItem> results = titleSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return BookItem.fromJson(data);
      }).toList();
      
      if (results.length < 5) {
        final descQuery = firestore.collection(booksCollection)
            .where('descriptionLowerCase', isGreaterThanOrEqualTo: normalizedQuery)
            .where('descriptionLowerCase', isLessThanOrEqualTo: '$normalizedQuery\uf8ff')
            .limit(10);
            
        final descSnapshot = await descQuery.get();
        final descResults = descSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return BookItem.fromJson(data);
        }).toList();
        
        for (final book in descResults) {
          if (!results.any((b) => b.id == book.id)) {
            results.add(book);
          }
        }
      }
      
      return results;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to search books: $e');
    }
  }

  @override
  Future<bool> uploadBook(BookItem book) async {
    try {
      if (book.title.isEmpty || book.description.isEmpty) {
        throw ArgumentError('Book title and description cannot be empty');
      }
      
      final docRef = book.id.isEmpty 
          ? firestore.collection(booksCollection).doc() 
          : firestore.collection(booksCollection).doc(book.id);
      
      final bookData = book.toJson();
      if (book.id.isEmpty) {
        bookData['id'] = docRef.id;
      }
      
      bookData['titleLowerCase'] = book.title.toLowerCase();
      bookData['descriptionLowerCase'] = book.description.toLowerCase();
      bookData['updatedAt'] = FieldValue.serverTimestamp();
      
      await docRef.set(bookData);
      
      if (_totalBooksCount != null) {
        _totalBooksCount = (_totalBooksCount ?? 0) + 1;
      }
      
      return true;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to upload book: $e');
    }
  }

  @override
  Future<bool> updateBook(String bookId, BookItem updatedBook) async {
    try {
      final docRef = firestore.collection(booksCollection).doc(bookId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        throw Exception('Book not found');
      }
      
      final updateData = updatedBook.toJson();
      
      updateData['titleLowerCase'] = updatedBook.title.toLowerCase();
      updateData['descriptionLowerCase'] = updatedBook.description.toLowerCase();
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      
      await docRef.update(updateData);
      
      return true;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to update book: $e');
    }
  }

  @override
  Future<bool> deleteBook(String bookId) async {
    try {
      final docRef = firestore.collection(booksCollection).doc(bookId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        throw Exception('Book not found');
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      
      await _deleteAssociatedFiles(data);
      await docRef.delete();
      
      if (_totalBooksCount != null && _totalBooksCount! > 0) {
        _totalBooksCount = _totalBooksCount! - 1;
      }
      
      return true;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }
  
  @override
  Future<(String, String)> uploadPdfFile(String bookId, File pdfFile) async {
    try {
      if (bookId.isEmpty) {
        throw ArgumentError('Book ID cannot be empty');
      }

      final storagePath = 'books/$bookId/book_pdf.pdf';
      final fileRef = storage.ref().child(storagePath);

      final uploadTask = await fileRef.putFile(
        pdfFile,
        SettableMetadata(contentType: 'application/pdf')
      );
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      if (downloadUrl.isEmpty) {
        throw Exception('Failed to get download URL');
      }
      
      return (downloadUrl, storagePath);
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to upload PDF: $e');
    }
  }
  
  @override
  Future<(String, String)> uploadCoverImage(String bookId, File imageFile) async {
    try {
      final storagePath = 'books/$bookId/cover_image.jpg';
      final fileRef = storage.ref().child(storagePath);
      
      final uploadTask = await fileRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg')
      );
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return (downloadUrl, storagePath);
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to upload cover image: $e');
    }
  }
  
  @override
  Future<DateTime?> getBookLastUpdated(String bookId) async {
    try {
      final docSnapshot = await firestore.collection(booksCollection).doc(bookId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      
      if (data.containsKey('updatedAt') && data['updatedAt'] != null) {
        return (data['updatedAt'] as Timestamp).toDate();
      }
      
      return null;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to get book last updated: $e');
    }
  }
  
  @override
  Future<File?> downloadPdfToLocal(String bookId, String localPath) async {
    try {
      final pdfUrl = await getPdfDownloadUrl(bookId);
      
      if (pdfUrl == null || pdfUrl.isEmpty) {
        return null;
      }
      
      final ref = storage.refFromURL(pdfUrl);
      final file = File(localPath);
      
      final dir = file.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      final downloadTask = ref.writeToFile(file);
      await downloadTask;
      
      if (await file.exists() && await file.length() > 0) {
        return file;
      } else {
        return null;
      }
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to download PDF: $e');
    }
  }

  @override
  Future<String?> getPdfDownloadUrl(String bookId) async {
    try {
      final docSnapshot = await firestore.collection(booksCollection).doc(bookId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      
      if (data.containsKey('pdfUrl') && data['pdfUrl'] != null) {
        return data['pdfUrl'] as String;
      }
      
      return null;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to get PDF URL: $e');
    }
  }

  @override
  Future<String?> regenerateUrlFromPath(String storagePath) async {
    try {
      if (storagePath.isEmpty) {
        return null;
      }
      
      final fileRef = storage.ref().child(storagePath);
      final downloadUrl = await fileRef.getDownloadURL();
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw Exception('Failed to regenerate URL: $e');
    }
  }

  @override
  Future<bool> verifyUrlIsWorking(String url) async {
    try {
      if (url.startsWith('https://firebasestorage.googleapis.com')) {
        try {
          final storageRef = storage.refFromURL(url);
          await storageRef.getMetadata();
          return true;
        } catch (e) {
          if (kDebugMode) {
            print('Storage URL validation failed: $e');
          }
          return false;
        }
      } else {
        final httpClient = HttpClient();
        final request = await httpClient.headUrl(Uri.parse(url));
        final response = await request.close();
        return response.statusCode >= 200 && response.statusCode < 300;
      }
    } catch (e) {
      return false;
    }
  }
  
  Exception _mapFirebaseException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('Permission denied: ${e.message}');
      case 'not-found':
        return Exception('Resource not found: ${e.message}');
      case 'unauthenticated':
      case 'unauthorized':
        return Exception('Authentication required: ${e.message}');
      case 'unavailable':
        return Exception('Service unavailable: ${e.message}');
      default:
        return Exception('Server error: ${e.message}');
    }
  }

  Future<void> _deleteAssociatedFiles(Map<String, dynamic> data) async {
    if (data.containsKey('pdfUrl') && data['pdfUrl'] != null) {
      try {
        final pdfRef = storage.refFromURL(data['pdfUrl'] as String);
        await pdfRef.delete();
      } catch (e) {
        // Log but continue
      }
    }
    
    if (data.containsKey('bookImage') && data['bookImage'] != null) {
      try {
        final imageRef = storage.refFromURL(data['bookImage'] as String);
        await imageRef.delete();
      } catch (e) {
        // Log but continue
      }
    }
  }

  void _updateTotalBooksCount(int count, {required bool isExact}) {
    if (isExact || _totalBooksCount == null || count > _totalBooksCount!) {
      _totalBooksCount = count;
      _lastCountFetch = DateTime.now();
    }
  }
}