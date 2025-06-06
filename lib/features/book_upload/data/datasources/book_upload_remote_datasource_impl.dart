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
  Future<BookItem> uploadBook(BookItem book, File pdfFile, {File? coverImageFile}) async {
    if (book.title.isEmpty || book.description.isEmpty) {
      throw Exception('Book title and description cannot be empty');
    }
    
    // Generate new document reference to get ID
    final collection = _getCollectionForCategory(book.courseCategory);
    final docRef = book.id.isEmpty 
        ? firestore.collection(collection).doc() 
        : firestore.collection(collection).doc(book.id);
    
    final bookId = docRef.id;
    var finalBook = book.copyWith(id: bookId);
    
    String? uploadedPdfPath;
    String? uploadedImagePath;
    
    try {
      // Upload PDF file first (required)
      final pdfResult = await _uploadPdfFile(bookId, pdfFile);
      uploadedPdfPath = pdfResult['storagePath'];
      finalBook = finalBook.copyWith(
        pdfUrl: pdfResult['url'],
        pdfPath: pdfResult['storagePath'],
      );
      
      // Upload cover image if provided (optional)
      if (coverImageFile != null) {
        try {
          final imageResult = await _uploadCoverImage(bookId, coverImageFile);
          uploadedImagePath = imageResult['storagePath'];
          finalBook = finalBook.copyWith(
            bookImage: imageResult['url'],
            bookImagePath: imageResult['storagePath'],
          );
        } catch (e) {
          // Clean up uploaded PDF before throwing
          await _deleteFileByPath(uploadedPdfPath!);
          throw Exception('Failed to upload cover image: $e');
        }
      }
      
      // Now create the book document with all data
      final bookData = finalBook.toJson();
      bookData['titleLowerCase'] = finalBook.title.toLowerCase();
      bookData['descriptionLowerCase'] = finalBook.description.toLowerCase();
      bookData['createdAt'] = FieldValue.serverTimestamp();
      bookData['updatedAt'] = FieldValue.serverTimestamp();
      
      await docRef.set(bookData);
      
      return finalBook.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
    } catch (e) {
      // Clean up any uploaded files on failure
      if (uploadedPdfPath != null) {
        await _deleteFileByPath(uploadedPdfPath);
      }
      if (uploadedImagePath != null) {
        await _deleteFileByPath(uploadedImagePath);
      }
      
      if (kDebugMode) {
        print('Error uploading book: $e');
      }
      rethrow;
    }
  }

  @override
  Future<BookItem> updateBook(String bookId, BookItem updatedBook, {File? pdfFile, File? coverImageFile}) async {
    try {
      final collection = _getCollectionForCategory(updatedBook.courseCategory);
      final docRef = firestore.collection(collection).doc(bookId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        throw Exception('Book not found');
      }
      
      final existingData = docSnapshot.data() as Map<String, dynamic>;
      var finalBook = updatedBook;
      
      String? newPdfPath;
      String? newImagePath;
      String? oldPdfPath = existingData['pdfPath'] as String?;
      String? oldImagePath = existingData['bookImagePath'] as String?;
      
      try {
        // Upload new PDF if provided
        if (pdfFile != null) {
          final pdfResult = await _uploadPdfFile(bookId, pdfFile);
          newPdfPath = pdfResult['storagePath'];
          finalBook = finalBook.copyWith(
            pdfUrl: pdfResult['url'],
            pdfPath: pdfResult['storagePath'],
          );
        }
        
        // Upload new cover image if provided
        if (coverImageFile != null) {
          try {
            final imageResult = await _uploadCoverImage(bookId, coverImageFile);
            newImagePath = imageResult['storagePath'];
            finalBook = finalBook.copyWith(
              bookImage: imageResult['url'],
              bookImagePath: imageResult['storagePath'],
            );
          } catch (e) {
            // Clean up uploaded PDF if image upload fails
            if (newPdfPath != null) {
              await _deleteFileByPath(newPdfPath);
            }
            throw Exception('Failed to upload new cover image: $e');
          }
        }
        
        // Update the document
        final updateData = finalBook.toJson();
        updateData['titleLowerCase'] = finalBook.title.toLowerCase();
        updateData['descriptionLowerCase'] = finalBook.description.toLowerCase();
        updateData['updatedAt'] = FieldValue.serverTimestamp();
        
        await docRef.update(updateData);
        
        // Only delete old files after successful update
        if (newPdfPath != null && oldPdfPath != null && oldPdfPath != newPdfPath) {
          await _deleteFileByPath(oldPdfPath);
        }
        if (newImagePath != null && oldImagePath != null && oldImagePath != newImagePath) {
          await _deleteFileByPath(oldImagePath);
        }
        
        // Return the updated book with current timestamp
        return finalBook.copyWith(updatedAt: DateTime.now());
        
      } catch (e) {
        // Clean up newly uploaded files on failure
        if (newPdfPath != null) {
          await _deleteFileByPath(newPdfPath);
        }
        if (newImagePath != null) {
          await _deleteFileByPath(newImagePath);
        }
        rethrow;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating book: $e');
      }
      rethrow;
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
          
          // Delete associated files first
          await _deleteAssociatedFiles(data);
          
          // Then delete the document
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

  /// Private helper method to upload PDF file atomically
  Future<Map<String, String>> _uploadPdfFile(String bookId, File pdfFile) async {
    try {
      final storagePath = 'books/$bookId/book_pdf.pdf';
      final fileRef = storage.ref().child(storagePath);

      final uploadTask = await fileRef.putFile(
        pdfFile,
        SettableMetadata(contentType: 'application/pdf')
      );
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      if (downloadUrl.isEmpty) {
        throw Exception('Failed to get download URL for uploaded PDF');
      }
      
      return {
        'url': downloadUrl,
        'storagePath': storagePath
      };
    } catch (e) {
      throw Exception('PDF upload failed: $e');
    }
  }
  
  /// Private helper method to upload cover image atomically
  Future<Map<String, String>> _uploadCoverImage(String bookId, File imageFile) async {
    try {
      final storagePath = 'books/$bookId/cover_image.jpg';
      final fileRef = storage.ref().child(storagePath);
      
      final uploadTask = await fileRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg')
      );
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      if (downloadUrl.isEmpty) {
        throw Exception('Failed to get download URL for uploaded cover image');
      }
      
      return {
        'url': downloadUrl,
        'storagePath': storagePath
      };
    } catch (e) {
      throw Exception('Cover image upload failed: $e');
    }
  }

  /// Private helper method to delete file by storage path
  Future<void> _deleteFileByPath(String storagePath) async {
    try {
      if (storagePath.isNotEmpty) {
        final fileRef = storage.ref().child(storagePath);
        await fileRef.delete();
      }
    } catch (e) {
      // Log but don't throw - cleanup failures shouldn't block operations
      if (kDebugMode) {
        print('Failed to delete file at $storagePath: $e');
      }
    }
  }

  /// Private helper method to delete all associated files
  Future<void> _deleteAssociatedFiles(Map<String, dynamic> data) async {
    // Delete PDF by path if exists
    if (data.containsKey('pdfPath') && data['pdfPath'] != null) {
      await _deleteFileByPath(data['pdfPath'] as String);
    }
    
    // Delete cover image by path if exists
    if (data.containsKey('bookImagePath') && data['bookImagePath'] != null) {
      await _deleteFileByPath(data['bookImagePath'] as String);
    }
    
    // Fallback: delete by URL
    if (data.containsKey('pdfUrl') && data['pdfUrl'] != null) {
      try {
        final pdfRef = storage.refFromURL(data['pdfUrl'] as String);
        await pdfRef.delete();
      } catch (e) {
        // Log but continue
        if (kDebugMode) {
          print('Failed to delete PDF by URL: $e');
        }
      }
    }
    
    if (data.containsKey('bookImage') && data['bookImage'] != null) {
      try {
        final imageRef = storage.refFromURL(data['bookImage'] as String);
        await imageRef.delete();
      } catch (e) {
        // Log but continue
        if (kDebugMode) {
          print('Failed to delete cover image by URL: $e');
        }
      }
    }
  }
}