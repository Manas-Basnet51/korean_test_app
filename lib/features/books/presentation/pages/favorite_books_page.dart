import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';
import 'package:korean_language_app/core/routes/app_router.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';
import 'package:korean_language_app/features/book_upload/presentation/bloc/file_upload_cubit.dart';
import 'package:korean_language_app/features/books/presentation/bloc/favorite_books/favorite_books_cubit.dart';
import 'package:korean_language_app/features/books/presentation/bloc/korean_books/korean_books_cubit.dart';
import 'package:korean_language_app/features/books/presentation/pages/book_edit_page.dart';
import 'package:korean_language_app/features/books/presentation/pages/pdf_viewer_page.dart';
import 'package:korean_language_app/features/books/presentation/widgets/book_grid.dart';
import 'package:korean_language_app/features/books/presentation/widgets/shimmer_loading_card.dart';

class FavoriteBooksPage extends StatefulWidget {
  const FavoriteBooksPage({super.key});

  @override
  State<FavoriteBooksPage> createState() => _FavoriteBooksPageState();
}

class _FavoriteBooksPageState extends State<FavoriteBooksPage> {
  final _scrollController = ScrollController();
  
  FavoriteBooksCubit get _favoriteBooksCubit => context.read<FavoriteBooksCubit>();
  KoreanBooksCubit get _koreanBooksCubit => context.read<KoreanBooksCubit>();
  LanguagePreferenceCubit get _languageCubit => context.read<LanguagePreferenceCubit>();
  FileUploadCubit get _fileUploadCubit => context.read<FileUploadCubit>();
  
  @override
  void initState() {
    super.initState();
    _favoriteBooksCubit.loadInitialBooks();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _toggleFavorite(BookItem book) {
    _favoriteBooksCubit.toggleFavorite(book);
  }
  
  Future<void> _refreshData() async {
    await _favoriteBooksCubit.hardRefresh();
  }

  Future<bool> _checkEditPermission(String bookId) async {
    final hasPermission = await _koreanBooksCubit.canUserEditBook(bookId);
    return hasPermission;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _languageCubit.getLocalizedText(
            korean: '즐겨찾기',
            english: 'Favorites',
          ),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: BlocBuilder<FavoriteBooksCubit, FavoriteBooksState>(
          builder: (context, state) {
            if (state is FavoriteBooksInitial || state is FavoriteBooksLoading) {
              return _buildLoadingState();
            } else if (state is FavoriteBooksError) {
              return _buildErrorView(state.message);
            } else if (state is FavoriteBooksLoaded) {
              final favoriteBooks = state.books;
              
              if (favoriteBooks.isEmpty) {
                return _buildEmptyFavoritesView();
              }
              
              return BooksGrid(
                books: favoriteBooks,
                scrollController: _scrollController,
                checkEditPermission: _checkEditPermission,
                onViewClicked: _viewPdf,
                onTestClicked: (book) {
                  // TODO: Implement test functionality
                },
                onEditClicked: _editBook,
                onDeleteClicked: _deleteBook,
                onToggleFavorite: _toggleFavorite,
                onInfoClicked: (book) {
                  //TODO
                },
                onDownloadClicked: (book) {
                  //TODO
                },
              );
            }
            
            return _buildEmptyFavoritesView();
          },
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 8, // Show 4 rows of loading cards
      itemBuilder: (context, index) => const ShimmerLoadingCard(),
    );
  }
  
  Widget _buildEmptyFavoritesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            _languageCubit.getLocalizedText(
              korean: '즐겨찾기가 없습니다',
              english: 'No favorites yet',
            ),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _languageCubit.getLocalizedText(
                korean: '책을 즐겨찾기에 추가하려면 하트 아이콘을 누르세요',
                english: 'Tap the heart icon on any book or course to add it to your favorites',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go(Routes.books),
            icon: const Icon(Icons.menu_book),
            label: Text(
              _languageCubit.getLocalizedText(
                korean: '책 찾아보기',
                english: 'Browse Books',
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getReadableErrorMessage(message),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  String _getReadableErrorMessage(String technicalError) {
    if (technicalError.contains('No internet connection')) {
      return 'You seem to be offline. Please check your connection and try again.';
    } else if (technicalError.contains('not found')) {
      return 'Your favorites could not be loaded.';
    } else {
      return 'There was an error loading your favorites. Please try again.';
    }
  }
  
  void _viewPdf(BookItem book) {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildPdfLoadingDialog(book.title),
    );
    
    // Load the PDF
    _koreanBooksCubit.loadBookPdf(book.id);
    
    // Listen for result
    _listenForPdfLoadingResult(book);
  }
  
  Widget _buildPdfLoadingDialog(String title) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Loading "$title"...',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This may take a moment',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  void _listenForPdfLoadingResult(BookItem book) {
    _koreanBooksCubit.stream.listen((state) {
      if (state is KoreanBookPdfLoaded && state.bookId == book.id) {
        // Close loading dialog
        // ignore: use_build_context_synchronously //TODO:what
        Navigator.of(context, rootNavigator: true).pop();
        // Open PDF
        _verifyAndOpenPdf(state.pdfFile, book.title);
      } else if (state is KoreanBookPdfError && state.bookId == book.id) {
        // Close loading dialog
        // ignore: use_build_context_synchronously //TODO: what
        Navigator.of(context, rootNavigator: true).pop();
        // Show error
        _showRetrySnackBar(
          _getReadableErrorMessage(state.message), 
          () => _viewPdf(book)
        );
      }
    });
  }
  
  void _showRetrySnackBar(String message, VoidCallback onRetry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: onRetry,
        ),
      ),
    );
  }
  
  void _verifyAndOpenPdf(File pdfFile, String title) async {
    try {
      final fileExists = await pdfFile.exists();
      final fileSize = fileExists ? await pdfFile.length() : 0;
      
      if (!fileExists || fileSize == 0) {
        throw Exception('PDF file is empty or does not exist');
      }
      
      Future.microtask(() => _openPdfViewer(pdfFile, title));
    } catch (e) {
      // ignore: use_build_context_synchronously //TODO: have a dedicated snackbar system
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: PDF file cannot be opened')),
      );
    }
  }
  
  void _openPdfViewer(File pdfFile, String title) {
    GoRouter.of(context).pushNamed(
      Routes.pdfViewer,
      extra: PDFViewerScreen(
        pdfFile: pdfFile,
        title: title,
      ),
    );
  }
  
  void _editBook(BookItem book) async {
    final hasPermission = await _koreanBooksCubit.canUserEditBook(book.id);
    if (!hasPermission) { 
      // ignore: use_build_context_synchronously //TODO: have a dedicated snackbar system
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to edit this book')),
      );
      return;
    }

    // ignore: use_build_context_synchronously //TODO:what
    final result = await context.push(
      Routes.editBooks,
      extra: BookEditPage(book: book)
    );

    if (result == true) {
      _refreshData();
    }
  }

  void _deleteBook(BookItem book) async {
    final hasPermission = await _koreanBooksCubit.canUserDeleteBook(book.id);
    if (!hasPermission) {
      // ignore: use_build_context_synchronously //TODO: have a dedicated snackbar system
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to delete this book')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      // ignore: use_build_context_synchronously //TODO: whatt
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text(
          'Are you sure you want to delete "${book.title}"? This action cannot be undone.'
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      final success = await _fileUploadCubit.deleteBook(book.id);
      if (success) {
        _koreanBooksCubit.removeBookFromState(book.id);
        _favoriteBooksCubit.toggleFavorite(book);
        // ignore: use_build_context_synchronously //TODO: have a dedicated snackbar system
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book deleted successfully')),
        );
      } else {
        // ignore: use_build_context_synchronously //TODO: have a dedicated snackbar system
        ScaffoldMessenger.of(context).showSnackBar( 
          const SnackBar(content: Text('Failed to delete book')),
        );
      }
    }
  }
}