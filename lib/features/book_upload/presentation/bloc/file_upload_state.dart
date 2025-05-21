part of 'file_upload_cubit.dart';

abstract class FileUploadState extends Equatable {
  const FileUploadState();
  
  @override
  List<Object?> get props => [];
}

// Initial state
class FileUploadInitial extends FileUploadState {}

// File picker loading state
class FilePickerLoading extends FileUploadState {
  final FileUploadType fileType;
  
  const FilePickerLoading(this.fileType);
  
  @override
  List<Object?> get props => [fileType];
}

// File picker success state
class FilePickerSuccess extends FileUploadState {
  final File file;
  final String fileName;
  final FileUploadType fileType;
  
  const FilePickerSuccess({
    required this.file,
    required this.fileName,
    required this.fileType,
  });
  
  @override
  List<Object?> get props => [file.path, fileName, fileType];
}

// File picker error state
class FilePickerError extends FileUploadState {
  final String message;
  final FileUploadType fileType;
  
  const FilePickerError(this.message, this.fileType);
  
  @override
  List<Object?> get props => [message, fileType];
}

// File uploading state
class FileUploading extends FileUploadState {
  final double progress;
  final FileUploadType fileType;
  
  const FileUploading(this.progress, this.fileType);
  
  @override
  List<Object?> get props => [progress, fileType];
}

// File upload success state
class FileUploadSuccess extends FileUploadState {
  final String bookId;
  final FileUploadType fileType;
  final BookItem? book;
  
  const FileUploadSuccess(this.bookId, this.fileType, {this.book});
  
  @override
  List<Object?> get props => [bookId, fileType, book];
}

// File upload error state
class FileUploadError extends FileUploadState {
  final String message;
  final FileUploadType fileType;
  
  const FileUploadError(this.message, this.fileType);
  
  @override
  List<Object?> get props => [message, fileType];
}

// File deletion states
class FileDeleting extends FileUploadState {
  final String bookId;
  
  const FileDeleting(this.bookId);
  
  @override
  List<Object?> get props => [bookId];
}

class FileDeletionSuccess extends FileUploadState {
  final String bookId;
  
  const FileDeletionSuccess(this.bookId);
  
  @override
  List<Object?> get props => [bookId];
}

class FileDeletionError extends FileUploadState {
  final String message;
  final String bookId;
  
  const FileDeletionError(this.message, this.bookId);
  
  @override
  List<Object?> get props => [message, bookId];
}