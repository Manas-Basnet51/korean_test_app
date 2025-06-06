import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:korean_language_app/core/enums/book_level.dart';
import 'package:korean_language_app/core/enums/course_category.dart';
import 'package:korean_language_app/core/enums/file_upload_type.dart';
import 'package:korean_language_app/features/books/presentation/bloc/korean_books/korean_books_cubit.dart';
import 'package:korean_language_app/features/book_upload/presentation/bloc/file_upload_cubit.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

class BookEditPage extends StatefulWidget {
  final BookItem book;
  
  const BookEditPage({
    super.key,
    required this.book,
  });

  @override
  State<BookEditPage> createState() => _BookEditPageState();
}

class _BookEditPageState extends State<BookEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  late TextEditingController _chaptersController;
  late TextEditingController _countryController;
  late TextEditingController _categoryController;
  
  late BookLevel _selectedLevel;
  late CourseCategory _selectedCategory;
  late IconData _selectedIcon;
  
  File? _selectedPdfFile;
  String? _pdfFileName;
  bool _pdfSelected = false;
  
  File? _selectedImageFile;
  String? _imageFileName;
  bool _imageSelected = false;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    context.read<FileUploadCubit>().resetState();
  }
  
  void _initializeControllers() {
    _titleController = TextEditingController(text: widget.book.title);
    _descriptionController = TextEditingController(text: widget.book.description);
    _durationController = TextEditingController(text: widget.book.duration);
    _chaptersController = TextEditingController(text: widget.book.chaptersCount.toString());
    _countryController = TextEditingController(text: widget.book.country);
    _categoryController = TextEditingController(text: widget.book.category);
    
    _selectedLevel = widget.book.level;
    _selectedCategory = widget.book.courseCategory;
    _selectedIcon = widget.book.icon;
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _chaptersController.dispose();
    _countryController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
  
  Future<void> _pickPdfFile() async {
    final file = await context.read<FileUploadCubit>().pickPdfFile();
    if (file != null) {
      setState(() {
        _selectedPdfFile = file;
        _pdfFileName = file.path.split('/').last;
        _pdfSelected = true;
      });
    }
  }
  
  Future<void> _pickImageFile() async {
    final file = await context.read<FileUploadCubit>().pickImageFile();
    if (file != null) {
      setState(() {
        _selectedImageFile = file;
        _imageFileName = file.path.split('/').last;
        _imageSelected = true;
      });
    }
  }
  
  Future<void> _updateBook() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    try {
      final updatedBook = widget.book.copyWith(
        title: _titleController.text,
        description: _descriptionController.text,
        duration: _durationController.text,
        chaptersCount: int.tryParse(_chaptersController.text) ?? widget.book.chaptersCount,
        icon: _selectedIcon,
        level: _selectedLevel,
        courseCategory: _selectedCategory,
        country: _countryController.text,
        category: _categoryController.text,
      );
      
      // Update book with optional new PDF and/or image atomically
      final success = await context.read<FileUploadCubit>().updateBook(
        widget.book.id,
        updatedBook,
        pdfFile: _selectedPdfFile,
        imageFile: _selectedImageFile,
      );
      
      if (success && mounted) {
        context.pop(true);
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating book: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Book',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: BlocConsumer<FileUploadCubit, FileUploadState>(
        listener: (context, state) {
          if (state is FileUploadSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Book updated successfully')),
            );
            if (state.book != null) {
              context.read<KoreanBooksCubit>().updateBookInState(state.book!);
            }
            Navigator.of(context).pop(true);
          } else if (state is FileUploadError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          bool isUploading = false;
          double uploadProgress = 0.0;
          
          if (state is FileUploading) {
            isUploading = true;
            uploadProgress = state.progress;
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Book Title',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book),
                    ),
                    enabled: !isUploading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Book Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    enabled: !isUploading,
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Book Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          decoration: const InputDecoration(
                            labelText: 'Duration',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.timer),
                          ),
                          enabled: !isUploading,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      Expanded(
                        child: TextFormField(
                          controller: _chaptersController,
                          decoration: const InputDecoration(
                            labelText: 'Chapters',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.format_list_numbered),
                          ),
                          enabled: !isUploading,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Numbers only';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _countryController,
                          decoration: const InputDecoration(
                            labelText: 'Country',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.public),
                          ),
                          enabled: !isUploading,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      Expanded(
                        child: TextFormField(
                          controller: _categoryController,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          enabled: !isUploading,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<BookLevel>(
                          value: _selectedLevel,
                          decoration: const InputDecoration(
                            labelText: 'Level',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.bar_chart),
                          ),
                          items: BookLevel.values.map((level) {
                            return DropdownMenuItem<BookLevel>(
                              value: level,
                              child: Text(level.toString().split('.').last),
                            );
                          }).toList(),
                          onChanged: isUploading 
                              ? null 
                              : (BookLevel? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedLevel = newValue;
                                    });
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      Expanded(
                        child: DropdownButtonFormField<CourseCategory>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Course Category',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.school),
                          ),
                          items: CourseCategory.values.map((category) {
                            if (category == CourseCategory.favorite) {
                              return null; // Skip favorite
                            }
                            return DropdownMenuItem<CourseCategory>(
                              value: category,
                              child: Text(category.toString().split('.').last),
                            );
                          }).where((item) => item != null).cast<DropdownMenuItem<CourseCategory>>().toList(),
                          onChanged: isUploading 
                              ? null 
                              : (CourseCategory? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedCategory = newValue;
                                    });
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Update PDF File (Optional)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  BlocBuilder<FileUploadCubit, FileUploadState>(
                    builder: (context, fileState) {
                      bool isPdfPickerLoading = fileState is FilePickerLoading && 
                                              fileState.fileType == FileUploadType.pdf;
                      
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _pdfSelected ? Colors.green : Colors.grey,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _pdfSelected ? Icons.check_circle : Icons.picture_as_pdf,
                                  color: _pdfSelected ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _pdfFileName ?? 
                                    (widget.book.pdfUrl != null ? 'Current PDF: ${widget.book.id}.pdf' : 'No PDF selected'),
                                    style: TextStyle(
                                      color: _pdfSelected ? Colors.green : Colors.grey,
                                      fontWeight: _pdfSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (fileState is FilePickerError && fileState.fileType == FileUploadType.pdf)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  fileState.message,
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: (isUploading || isPdfPickerLoading) ? null : _pickPdfFile,
                                icon: isPdfPickerLoading 
                                    ? const SizedBox(
                                        width: 16, 
                                        height: 16, 
                                        child: CircularProgressIndicator(strokeWidth: 2)
                                      )
                                    : const Icon(Icons.upload_file),
                                label: Text(isPdfPickerLoading ? 'Selecting...' : 'Select New PDF File'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Update Cover Image (Optional)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  BlocBuilder<FileUploadCubit, FileUploadState>(
                    builder: (context, fileState) {
                      bool isImagePickerLoading = fileState is FilePickerLoading && 
                                              fileState.fileType == FileUploadType.image;
                      
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _imageSelected ? Colors.green : Colors.grey,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedImageFile != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImageFile!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            if (_selectedImageFile == null && widget.book.bookImage != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: widget.book.bookImage!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) => Center(
                                    child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                                  ),
                                ),
                              ),
                            if (_selectedImageFile != null || widget.book.bookImage != null) 
                              const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Icon(
                                  _imageSelected ? Icons.check_circle : Icons.image,
                                  color: _imageSelected ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _imageFileName ?? 
                                    (widget.book.bookImage != null ? 'Current image' : 'No image selected'),
                                    style: TextStyle(
                                      color: _imageSelected ? Colors.green : Colors.grey,
                                      fontWeight: _imageSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (fileState is FilePickerError && fileState.fileType == FileUploadType.image)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  fileState.message,
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: (isUploading || isImagePickerLoading) ? null : _pickImageFile,
                                icon: isImagePickerLoading 
                                    ? const SizedBox(
                                        width: 16, 
                                        height: 16, 
                                        child: CircularProgressIndicator(strokeWidth: 2)
                                      )
                                    : const Icon(Icons.upload_file),
                                label: Text(isImagePickerLoading ? 'Selecting...' : 'Select New Cover Image'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.secondary,
                                  foregroundColor: colorScheme.onSecondary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  if (isUploading)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: uploadProgress,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Updating ${(uploadProgress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(color: colorScheme.primary),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isUploading ? null : _updateBook,
                      icon: Icon(isUploading ? Icons.hourglass_top : Icons.save),
                      label: Text(isUploading ? 'Updating...' : 'Save Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}