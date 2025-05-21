import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:korean_language_app/core/enums/course_category.dart';
import 'package:korean_language_app/features/book_upload/data/datasources/book_upload_remote_datasource.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

class FirestoreBookUploadDataSource implements BookUploadRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final Map<CourseCategory, String> collectionMap = {
    CourseCategory.korean: 'korean_books',
    CourseCategory.nepali: 'nepali_books',
    CourseCategory.test: 'test_books',
    CourseCategory.global: 'global_books',
  };
  
  FirestoreBookUploadDataSource({
    required this.firestore,
    required this.storage,
  });

  String _getCollectionForCategory(CourseCategory category) {
    return collectionMap[category] ?? 'korean_books';
  }

  @override
  Future<Map<String, String>?> uploadPdfFile(String bookId, File pdfFile) async {
    try {
      if (bookId.isEmpty) {
        return null;
      }

      final storagePath = 'books/$bookId/book_pdf.pdf';
      final fileRef = storage.ref().child(storagePath);

      final uploadTask = await fileRef.putFile(
        pdfFile,
        SettableMetadata(contentType: 'application/pdf')
      );
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      if (downloadUrl.isEmpty) {
        return null;
      }
      
      return {
        'url': downloadUrl,
        'storagePath': storagePath
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading PDF file: $e');
      }
      if (e.toString().contains('storage/unauthorized')) {
        throw Exception('Storage permission denied. Check Firebase Storage rules.');
      }
      return null;
    }
  }
  
  @override
  Future<Map<String, String>?> uploadCoverImage(String bookId, File imageFile) async {
    try {
      final storagePath = 'books/$bookId/cover_image.jpg';
      final fileRef = storage.ref().child(storagePath);
      
      final uploadTask = await fileRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg')
      );
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return {
        'url': downloadUrl,
        'storagePath': storagePath
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading cover image: $e');
      }
      if (e.toString().contains('storage/unauthorized')) {
        throw Exception('Storage permission denied. Check Firebase Storage rules.');
      }
      return null;
    }
  }

  @override
  Future<bool> uploadBook(BookItem book) async {
    try {
      if (book.title.isEmpty || book.description.isEmpty) {
        throw Exception('Book title and description cannot be empty');
      }
      
      final collection = _getCollectionForCategory(book.courseCategory);
      final docRef = book.id.isEmpty 
          ? firestore.collection(collection).doc() 
          : firestore.collection(collection).doc(book.id);
      
      final bookData = book.toJson();
      if (book.id.isEmpty) {
        bookData['id'] = docRef.id;
      }
      
      bookData['titleLowerCase'] = book.title.toLowerCase();
      bookData['descriptionLowerCase'] = book.description.toLowerCase();
      bookData['createdAt'] = FieldValue.serverTimestamp();
      bookData['updatedAt'] = FieldValue.serverTimestamp();
      
      await docRef.set(bookData);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading book: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> updateBook(String bookId, BookItem updatedBook) async {
    try {
      final collection = _getCollectionForCategory(updatedBook.courseCategory);
      final docRef = firestore.collection(collection).doc(bookId);
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
    } catch (e) {
      if (kDebugMode) {
        print('Error updating book: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> deleteBook(String bookId) async {
    try {
      // Try to find and delete the book from each collection
      for (var collection in collectionMap.values) {
        final docRef = firestore.collection(collection).doc(bookId);
        final docSnapshot = await docRef.get();
        
        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>;
          
          // Delete PDF file if exists
          if (data.containsKey('pdfUrl') && data['pdfUrl'] != null) {
            try {
              final pdfRef = storage.refFromURL(data['pdfUrl'] as String);
              await pdfRef.delete();
            } catch (e) {
              // Log but continue
              if (kDebugMode) {
                print('Error deleting PDF file: $e');
              }
            }
          }
          
          // Delete cover image if exists
          if (data.containsKey('bookImage') && data['bookImage'] != null) {
            try {
              final imageRef = storage.refFromURL(data['bookImage'] as String);
              await imageRef.delete();
            } catch (e) {
              // Log but continue
              if (kDebugMode) {
                print('Error deleting cover image: $e');
              }
            }
          }
          
          await docRef.delete();
          return true;
        }
      }
      
      return false; // Book not found in any collection
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting book: $e');
      }
      return false;
    }
  }

  @override
  Future<List<BookItem>> searchBookById(String bookId) async {
    try {
      final results = <BookItem>[];
      
      // Search in each collection
      for (var entry in collectionMap.entries) {
        final category = entry.key;
        final collection = entry.value;
        
        final docSnapshot = await firestore.collection(collection).doc(bookId).get();
        
        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>;
          data['id'] = docSnapshot.id;
          data['courseCategory'] = category.toString().split('.').last;
          
          results.add(BookItem.fromJson(data));
        }
      }
      
      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Error searching book by ID: $e');
      }
      return [];
    }
  }

  @override
  Future<BookItem?> getBookById(String bookId) async {
    try {
      final books = await searchBookById(bookId);
      return books.isNotEmpty ? books.first : null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting book by ID: $e');
      }
      return null;
    }
  }
}