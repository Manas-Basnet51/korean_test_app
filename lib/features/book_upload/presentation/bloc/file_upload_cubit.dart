import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/enums/file_upload_type.dart';
import 'package:korean_language_app/core/services/auth_service.dart';
import 'package:korean_language_app/features/auth/domain/entities/user.dart';
import 'package:korean_language_app/features/book_upload/domain/repositories/book_upload_repository.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

part 'file_upload_state.dart';

class FileUploadCubit extends Cubit<FileUploadState> {
  final BookUploadRepository uploadRepository;
  final AuthService authService;
  
  FileUploadCubit({
    required this.uploadRepository,
    required this.authService,
  }) : super(FileUploadInitial());
  
  Future<File?> pickPdfFile() async {
    emit(const FilePickerLoading(FileUploadType.pdf));
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final fileName = result.files.first.name;
        
        if (await _isPdfValid(file)) {
          emit(FilePickerSuccess(
            file: file, 
            fileName: fileName, 
            fileType: FileUploadType.pdf
          ));
          return file;
        } else {
          emit(const FilePickerError(
            'The selected PDF file appears to be invalid or corrupted.',
            FileUploadType.pdf
          ));
        }
      } else {
        emit(FileUploadInitial());
      }
    } catch (e) {
      emit(FilePickerError('Could not select PDF file: $e', FileUploadType.pdf));
    }
    return null;
  }
  
  Future<File?> pickImageFile() async {
    emit(const FilePickerLoading(FileUploadType.image));
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final fileName = result.files.first.name;
        
        if (await _isImageValid(file)) {
          emit(FilePickerSuccess(
            file: file, 
            fileName: fileName, 
            fileType: FileUploadType.image
          ));
          return file;
        } else {
          emit(const FilePickerError(
            'The selected image appears to be invalid.',
            FileUploadType.image
          ));
        }
      } else {
        emit(FileUploadInitial());
      }
    } catch (e) {
      emit(FilePickerError('Could not select image file: $e', FileUploadType.image));
    }
    return null;
  }
  
  Future<bool> uploadBook(BookItem book, File pdfFile, File? imageFile) async {
    final isConnected = await _checkConnectivity();
    if (!isConnected) {
      emit(const FileUploadError('No internet connection', FileUploadType.pdf));
      return false;
    }
    
    try {
      final user = _getCurrentUser();
      if (user == null) {
        emit(const FileUploadError('User not authenticated', FileUploadType.pdf));
        return false;
      }
      
      emit(const FileUploading(0.1, FileUploadType.pdf));
      
      final String newBookId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final bookWithId = book.copyWith(
        id: newBookId,
        creatorUid: user.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      emit(const FileUploading(0.3, FileUploadType.pdf));
      
      final pdfResult = await uploadRepository.uploadPdfFile(newBookId, pdfFile);
      
      if (pdfResult.isFailure) {
        emit(FileUploadError(pdfResult.error ?? 'Failed to upload PDF file', FileUploadType.pdf));
        return false;
      }
      
      final pdfData = pdfResult.data ?? {};
      BookItem updatedBook = bookWithId.copyWith(
        pdfUrl: pdfData['url'],
        pdfPath: pdfData['storagePath'],
      );
      
      if (imageFile != null) {
        emit(const FileUploading(0.6, FileUploadType.pdf));
        final imageResult = await uploadRepository.uploadCoverImage(newBookId, imageFile);
        
        if (imageResult.isSuccess) {
          final imageData = imageResult.data ?? {};
          updatedBook = updatedBook.copyWith(
            bookImage: imageData['url'],
            bookImagePath: imageData['storagePath'],
          );
        }
      }
      
      emit(const FileUploading(0.8, FileUploadType.pdf));
      
      final createResult = await uploadRepository.createBook(updatedBook);
      
      if (createResult.isFailure) {
        emit(FileUploadError(createResult.error ?? 'Failed to upload book metadata', FileUploadType.pdf));
        return false;
      }
      
      final finalBook = createResult.data ?? updatedBook;
      emit(FileUploadSuccess(newBookId, FileUploadType.pdf, book: finalBook));
      return true;
    } catch (e) {
      emit(FileUploadError('Upload failed: $e', FileUploadType.pdf));
      return false;
    }
  }
  
  Future<bool> updateBook(String bookId, BookItem updatedBook, {File? pdfFile, File? imageFile}) async {
    final isConnected = await _checkConnectivity();
    if (!isConnected) {
      emit(const FileUploadError('No internet connection', FileUploadType.pdf));
      return false;
    }
    
    try {
      final user = _getCurrentUser();
      if (user == null) {
        emit(const FileUploadError('User not authenticated', FileUploadType.pdf));
        return false;
      }
      
      final permissionResult = await uploadRepository.hasEditPermission(bookId, user.uid);
      if (permissionResult.isFailure || !(permissionResult.data ?? false)) {
        emit(const FileUploadError('You do not have permission to edit this book', FileUploadType.pdf));
        return false;
      }
      
      emit(const FileUploading(0.1, FileUploadType.pdf));
      
      var updatedBookWithMeta = updatedBook.copyWith(
        updatedAt: DateTime.now(),
      );
      
      if (pdfFile != null) {
        emit(const FileUploading(0.3, FileUploadType.pdf));
        final pdfResult = await uploadRepository.uploadPdfFile(bookId, pdfFile);
        
        if (pdfResult.isSuccess) {
          final pdfData = pdfResult.data ?? {};
          updatedBookWithMeta = updatedBookWithMeta.copyWith(
            pdfUrl: pdfData['url'],
            pdfPath: pdfData['storagePath'],
          );
        }
      }
      
      if (imageFile != null) {
        emit(const FileUploading(0.6, FileUploadType.pdf));
        final imageResult = await uploadRepository.uploadCoverImage(bookId, imageFile);
        
        if (imageResult.isSuccess) {
          final imageData = imageResult.data ?? {};
          updatedBookWithMeta = updatedBookWithMeta.copyWith(
            bookImage: imageData['url'],
            bookImagePath: imageData['storagePath'],
          );
        }
      }
      
      emit(const FileUploading(0.8, FileUploadType.pdf));
      
      final updateResult = await uploadRepository.updateBook(bookId, updatedBookWithMeta);
      
      if (updateResult.isFailure) {
        emit(FileUploadError(updateResult.error ?? 'Failed to update book metadata', FileUploadType.pdf));
        return false;
      }
      
      final finalBook = updateResult.data ?? updatedBookWithMeta;
      emit(FileUploadSuccess(bookId, FileUploadType.pdf, book: finalBook));
      return true;
    } catch (e) {
      emit(FileUploadError('Update failed: $e', FileUploadType.pdf));
      return false;
    }
  }
  
  Future<bool> deleteBook(String bookId) async {
    final isConnected = await _checkConnectivity();
    if (!isConnected) {
      emit(const FileUploadError('No internet connection', FileUploadType.pdf));
      return false;
    }
    
    try {
      final user = _getCurrentUser();
      if (user == null) {
        emit(const FileUploadError('User not authenticated', FileUploadType.pdf));
        return false;
      }
      
      final permissionResult = await uploadRepository.hasDeletePermission(bookId, user.uid);
      if (permissionResult.isFailure || !(permissionResult.data ?? false)) {
        emit(const FileUploadError('You do not have permission to delete this book', FileUploadType.pdf));
        return false;
      }
      
      emit(FileDeleting(bookId));
      final deleteResult = await uploadRepository.deleteBook(bookId);
      
      if (deleteResult.isFailure) {
        emit(FileDeletionError(deleteResult.error ?? 'Failed to delete book', bookId));
        return false;
      }
      
      emit(FileDeletionSuccess(bookId));
      return true;
    } catch (e) {
      emit(FileDeletionError('Delete failed: $e', bookId));
      return false;
    }
  }
  
  UserEntity? _getCurrentUser() {
    return authService.getCurrentUser();
  }
  
  void resetState() {
    emit(FileUploadInitial());
  }
  
  Future<bool> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  Future<bool> _isPdfValid(File pdfFile) async {
    try {
      final fileSize = await pdfFile.length();
      if (fileSize > 20 * 1024 * 1024 || fileSize < 100) {
        return false;
      }
      
      final bytes = await pdfFile.openRead(0, 5).toList();
      final data = bytes.expand((x) => x).toList();
      
      return data.length >= 5 && String.fromCharCodes(data.sublist(0, 5)) == '%PDF-';
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> _isImageValid(File imageFile) async {
    try {
      final fileSize = await imageFile.length();
      return fileSize <= 10 * 1024 * 1024 && fileSize >= 10;
    } catch (e) {
      return false;
    }
  }
}