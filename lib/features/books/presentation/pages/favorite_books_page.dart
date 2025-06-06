import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/core/presentation/connectivity/bloc/connectivity_cubit.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';
import 'package:korean_language_app/core/presentation/snackbar/bloc/snackbar_cubit.dart';
import 'package:korean_language_app/core/presentation/widgets/errors/error_widget.dart';
import 'package:korean_language_app/core/routes/app_router.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';
import 'package:korean_language_app/features/book_upload/presentation/bloc/file_upload_cubit.dart';
import 'package:korean_language_app/features/books/presentation/bloc/favorite_books/favorite_books_cubit.dart';
import 'package:korean_language_app/features/books/presentation/bloc/korean_books/korean_books_cubit.dart';
import 'package:korean_language_app/features/book_upload/presentation/pages/book_edit_page.dart';
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
  bool _isInitialized = false;
  
  StreamSubscription<KoreanBooksState>? _pdfLoadingSubscription;
  
  FavoriteBooksCubit get _favoriteBooksCubit => context.read<FavoriteBooksCubit>();
  KoreanBooksCubit get _koreanBooksCubit => context.read<KoreanBooksCubit>();
  LanguagePreferenceCubit get _languageCubit => context.read<LanguagePreferenceCubit>();
  FileUploadCubit get _fileUploadCubit => context.read<FileUploadCubit>();
  SnackBarCubit get _snackBarCubit => context.read<SnackBarCubit>();
  
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _favoriteBooksCubit.loadInitialBooks();
      context.read<ConnectivityCubit>().checkConnectivity();
      setState(() {
        _isInitialized = true;
      });
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _pdfLoadingSubscription?.cancel();
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
    
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
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
      body: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, connectivityState) {
          final bool isOffline = connectivityState is ConnectivityDisconnected;
          
          return Column(
            children: [
              if (isOffline)
                ErrorView(
                  message: '',
                  errorType: FailureType.network,
                  onRetry: () {
                    context.read<ConnectivityCubit>().checkConnectivity();
                  },
                  isCompact: true,
                ),
              
              Expanded(
                child: _buildFavoriteBooksContent(isOffline),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildFavoriteBooksContent(bool isOffline) {
    return BlocConsumer<FavoriteBooksCubit, FavoriteBooksState>(
      listener: (context, state) {
        final operation = state.currentOperation;
        
        if (operation.status == FavoriteBooksOperationStatus.failed) {
          String errorMessage = operation.message ?? 'Operation failed';
          
          switch (operation.type) {
            case FavoriteBooksOperationType.loadBooks:
              errorMessage = 'Failed to load favorite books';
              break;
            case FavoriteBooksOperationType.searchBooks:
              errorMessage = 'Failed to search favorite books';
              break;
            case FavoriteBooksOperationType.toggleFavorite:
              errorMessage = 'Failed to toggle favorite status';
              break;
            case FavoriteBooksOperationType.refreshBooks:
              errorMessage = 'Failed to refresh favorite books';
              break;
            default:
              break;
          }
          
          _snackBarCubit.showErrorLocalized(
            korean: errorMessage,
            english: errorMessage,
          );
        }
        
        if (state.hasError) {
          _snackBarCubit.showErrorLocalized(
            korean: state.error ?? '오류가 발생했습니다.',
            english: state.error ?? 'An error occurred.',
          );
        }
      },
      builder: (context, state) {
        // FIXED: Removed cachedState references and simplified logic
        
        // If offline and we have no data, show offline message
        if (isOffline && state.books.isEmpty && state.isLoading) {
          return ErrorView(
            message: '',
            errorType: FailureType.network,
            onRetry: () {
              context.read<ConnectivityCubit>().checkConnectivity();
              if (context.read<ConnectivityCubit>().state is ConnectivityConnected) {
                _favoriteBooksCubit.loadInitialBooks();
              }
            },
          );
        }
        
        // If loading and no data, show loading state
        if (state.isLoading && state.books.isEmpty) {
          return _buildLoadingState();
        }
        
        // If error and no data, show error message with retry button
        if (state.hasError && state.books.isEmpty) {
          return ErrorView(
            message: state.error ?? '',
            errorType: state.errorType,
            onRetry: () {
              _favoriteBooksCubit.loadInitialBooks();
            },
          );
        }
        
        // Show favorites content (with error banner if there's an error but we have data)
        return _buildFavoritesList(state);
      },
    );
  }
  
  Widget _buildFavoritesList(FavoriteBooksState state) {
    if (state.books.isEmpty) {
      return _buildEmptyFavoritesView();
    }
    
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Column(
        children: [
          // Show error banner if there's an error but we have cached data
          if (state.hasError)
            ErrorView(
              message: state.error ?? '',
              errorType: state.errorType,
              onRetry: () {
                _favoriteBooksCubit.loadInitialBooks();
              },
              isCompact: true,
            ),
          
          Expanded(
            child: BooksGrid(
              books: state.books,
              scrollController: _scrollController,
              checkEditPermission: _checkEditPermission,
              onViewClicked: _viewPdf,
              onTestClicked: (book) {
                _snackBarCubit.showInfoLocalized(
                  korean: '테스트 기능이 곧 제공될 예정입니다',
                  english: 'Test functionality coming soon',
                );
              },
              onEditClicked: _editBook,
              onDeleteClicked: _deleteBook,
              onToggleFavorite: _toggleFavorite,
              onInfoClicked: (book) {
                // TODO: Implement book info
              },
              onDownloadClicked: (book) {
                // TODO: Implement download
              },
            ),
          ),
        ],
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
      itemCount: 8,
      itemBuilder: (context, index) => const ShimmerLoadingCard(),
    );
  }
  
  Widget _buildEmptyFavoritesView() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
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
        ),
      ),
    );
  }
  
  void _viewPdf(BookItem book) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildPdfLoadingDialog(book.title),
    );
    
    _koreanBooksCubit.loadBookPdf(book.id);
    
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
            _languageCubit.getLocalizedText(
              korean: '"$title" 로딩 중...',
              english: 'Loading "$title"...',
            ),
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _languageCubit.getLocalizedText(
              korean: '잠시만 기다려주세요',
              english: 'This may take a moment',
            ),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  void _listenForPdfLoadingResult(BookItem book) {
    _pdfLoadingSubscription?.cancel();
    
    _pdfLoadingSubscription = _koreanBooksCubit.stream.listen((state) {
      if (state.currentOperation.type == KoreanBooksOperationType.loadPdf && 
          state.currentOperation.bookId == book.id) {
        
        if (state.currentOperation.status == KoreanBooksOperationStatus.completed && 
            state.loadedPdfFile != null) {
          Navigator.of(context, rootNavigator: true).pop();
          _verifyAndOpenPdf(state.loadedPdfFile!, book.title);
          _pdfLoadingSubscription?.cancel();
        } else if (state.currentOperation.status == KoreanBooksOperationStatus.failed) {
          Navigator.of(context, rootNavigator: true).pop();
          _showRetrySnackBar(
            _getReadableErrorMessage(state.currentOperation.message ?? 'Failed to load PDF'), 
            () => _viewPdf(book),
          );
          _pdfLoadingSubscription?.cancel();
        }
      }
    });
  }
  
  String _getReadableErrorMessage(String technicalError) {
    if (technicalError.contains('No internet connection')) {
      return _languageCubit.getLocalizedText(
        korean: '오프라인 상태인 것 같습니다. 연결을 확인하고 다시 시도하세요.',
        english: 'You seem to be offline. Please check your connection and try again.',
      );
    } else if (technicalError.contains('not found')) {
      return _languageCubit.getLocalizedText(
        korean: '죄송합니다. PDF를 찾을 수 없습니다.',
        english: 'Sorry, the book PDF could not be found.',
      );
    } else if (technicalError.contains('corrupted') || technicalError.contains('empty')) {
      return _languageCubit.getLocalizedText(
        korean: '죄송합니다. PDF 파일이 손상된 것 같습니다.',
        english: 'Sorry, the PDF file appears to be damaged.',
      );
    } else {
      return _languageCubit.getLocalizedText(
        korean: 'PDF를 로드할 수 없습니다. 다시 시도하세요.',
        english: 'Could not load the PDF. Please try again.',
      );
    }
  }
  
  void _showRetrySnackBar(String message, VoidCallback onRetry) {
    _snackBarCubit.showErrorLocalized(
      korean: message,
      english: message,
      actionLabelKorean: '다시 시도',
      actionLabelEnglish: 'Retry',
      action: onRetry,
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
      _snackBarCubit.showErrorLocalized(
        korean: '오류: PDF 파일을 열 수 없습니다',
        english: 'Error: PDF file cannot be opened',
      );
    }
  }
  
  void _openPdfViewer(File pdfFile, String title) {
    context.push(
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
      _snackBarCubit.showErrorLocalized(
        korean: '이 책을 편집할 권한이 없습니다',
        english: 'You do not have permission to edit this book',
      );
      return;
    }

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
      _snackBarCubit.showErrorLocalized(
        korean: '이 책을 삭제할 권한이 없습니다',
        english: 'You do not have permission to delete this book',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _languageCubit.getLocalizedText(
            korean: '책 삭제',
            english: 'Delete Book',
          ),
        ),
        content: Text(
          _languageCubit.getLocalizedText(
            korean: '"${book.title}"을(를) 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.',
            english: 'Are you sure you want to delete "${book.title}"? This action cannot be undone.',
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              _languageCubit.getLocalizedText(
                korean: '취소',
                english: 'CANCEL',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              _languageCubit.getLocalizedText(
                korean: '삭제',
                english: 'DELETE',
              ),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      final success = await _fileUploadCubit.deleteBook(book.id);
      if (success) {
        _koreanBooksCubit.removeBookFromState(book.id);
        _favoriteBooksCubit.toggleFavorite(book);
        _snackBarCubit.showSuccessLocalized(
          korean: '책이 성공적으로 삭제되었습니다',
          english: 'Book deleted successfully',
        );
      } else {
        _snackBarCubit.showErrorLocalized(
          korean: '책 삭제에 실패했습니다',
          english: 'Failed to delete book',
        );
      }
    }
  }
}