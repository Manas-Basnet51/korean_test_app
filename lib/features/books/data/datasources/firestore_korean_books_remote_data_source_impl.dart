import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:korean_language_app/core/data/base_datasource.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/features/books/data/datasources/korean_books_remote_data_source.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

class FirestoreKoreanBooksDataSource extends BaseDataSource implements KoreanBooksRemoteDataSource {
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
  Future<ApiResult<List<BookItem>>> getKoreanBooks({int page = 0, int pageSize = 5}) {
    return handleAsyncDataSourceCall(() async {
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
    });
  }

  @override
  Future<ApiResult<bool>> hasMoreBooks(int currentCount) {
    return handleAsyncDataSourceCall(() async {
      if (_totalBooksCount != null && 
          _lastCountFetch != null &&
          DateTime.now().difference(_lastCountFetch!).inMinutes < 5) {
        return currentCount < _totalBooksCount!;
      }
      
      final countQuery = await firestore.collection(booksCollection).count().get();
      _updateTotalBooksCount(countQuery.count!, isExact: true);
      
      return currentCount < _totalBooksCount!;
    });
  }

  @override
  Future<ApiResult<List<BookItem>>> searchKoreanBooks(String query) {
    return handleAsyncDataSourceCall(() async {
      final normalizedQuery = query.toLowerCase();
      
      final querySnapshot = await firestore.collection(booksCollection)
          .where('titleLowerCase', isGreaterThanOrEqualTo: normalizedQuery)
          .where('titleLowerCase', isLessThanOrEqualTo: '$normalizedQuery\uf8ff')
          .limit(10)
          .get();
      
      final List<BookItem> results = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return BookItem.fromJson(data);
      }).toList();
      
      if (results.length < 5) {
        final descQuerySnapshot = await firestore.collection(booksCollection)
            .where('descriptionLowerCase', isGreaterThanOrEqualTo: normalizedQuery)
            .where('descriptionLowerCase', isLessThanOrEqualTo: '$normalizedQuery\uf8ff')
            .limit(10)
            .get();
            
        final descResults = descQuerySnapshot.docs.map((doc) {
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
    });
  }

  @override
  Future<ApiResult<bool>> uploadBook(BookItem book) {
    return handleAsyncDataSourceCall(() async {
      if (book.title.isEmpty || book.description.isEmpty) {
        throw Exception('Book title and description cannot be empty');
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
    });
  }

  @override
  Future<ApiResult<bool>> updateBook(String bookId, BookItem updatedBook) {
    return handleAsyncDataSourceCall(() async {
      final docRef = firestore.collection(booksCollection).doc(bookId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        return false;
      }
      
      final updateData = updatedBook.toJson();
      
      updateData['titleLowerCase'] = updatedBook.title.toLowerCase();
      updateData['descriptionLowerCase'] = updatedBook.description.toLowerCase();
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      
      await docRef.update(updateData);
      
      return true;
    });
  }

  @override
  Future<ApiResult<bool>> deleteBook(String bookId) {
    return handleAsyncDataSourceCall(() async {
      final docRef = firestore.collection(booksCollection).doc(bookId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        return false;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      
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
      
      await docRef.delete();
      
      if (_totalBooksCount != null && _totalBooksCount! > 0) {
        _totalBooksCount = _totalBooksCount! - 1;
      }
      
      return true;
    });
  }
  
  @override
  Future<ApiResult<(String, String)>> uploadPdfFile(String bookId, File pdfFile) {
    return handleAsyncDataSourceCall(() async {
      if (bookId.isEmpty) {
        throw Exception('Book ID cannot be empty');
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
    });
  }
  
  @override
  Future<ApiResult<(String, String)>> uploadCoverImage(String bookId, File imageFile) {
    return handleAsyncDataSourceCall(() async {
      final storagePath = 'books/$bookId/cover_image.jpg';
      final fileRef = storage.ref().child(storagePath);
      
      final uploadTask = await fileRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg')
      );
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return (downloadUrl, storagePath);
    });
  }
  
  @override
  Future<ApiResult<DateTime?>> getBookLastUpdated(String bookId) {
    return handleAsyncDataSourceCall(() async {
      final docSnapshot = await firestore.collection(booksCollection).doc(bookId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      
      if (data.containsKey('updatedAt') && data['updatedAt'] != null) {
        return (data['updatedAt'] as Timestamp).toDate();
      }
      
      return null;
    });
  }
  
  @override
  Future<ApiResult<File?>> downloadPdfToLocal(String bookId, String localPath) {
    return handleAsyncDataSourceCall(() async {
      final pdfUrlResult = await getPdfDownloadUrl(bookId);
      
      if (!pdfUrlResult.isSuccess || pdfUrlResult.data == null || pdfUrlResult.data!.isEmpty) {
        return null;
      }
      
      final pdfUrl = pdfUrlResult.data!;
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
    });
  }

  @override
  Future<ApiResult<String?>> getPdfDownloadUrl(String bookId) {
    return handleAsyncDataSourceCall(() async {
      final docSnapshot = await firestore.collection(booksCollection).doc(bookId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      
      if (data.containsKey('pdfUrl') && data['pdfUrl'] != null) {
        return data['pdfUrl'] as String;
      }
      
      return null;
    });
  }

  @override
  Future<ApiResult<String?>> regenerateUrlFromPath(String storagePath) {
    return handleAsyncDataSourceCall(() async {
      if (storagePath.isEmpty) {
        return null;
      }
      
      final fileRef = storage.ref().child(storagePath);
      final downloadUrl = await fileRef.getDownloadURL();
      
      return downloadUrl;
    });
  }

  @override
  Future<ApiResult<bool>> verifyUrlIsWorking(String url) {
    return handleAsyncDataSourceCall(() async {
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
        final http = await HttpClient().headUrl(Uri.parse(url));
        final response = await http.close();
        return response.statusCode >= 200 && response.statusCode < 300;
      }
    });
  }
  
  void _updateTotalBooksCount(int count, {required bool isExact}) {
    if (isExact || _totalBooksCount == null || count > _totalBooksCount!) {
      _totalBooksCount = count;
      _lastCountFetch = DateTime.now();
    }
  }
}