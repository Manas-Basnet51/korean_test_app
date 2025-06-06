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
import 'package:korean_language_app/core/enums/course_category.dart';
import 'package:korean_language_app/features/books/presentation/bloc/favorite_books/favorite_books_cubit.dart';
import 'package:korean_language_app/features/books/presentation/bloc/korean_books/korean_books_cubit.dart';
import 'package:korean_language_app/features/book_upload/presentation/bloc/file_upload_cubit.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';
import 'package:korean_language_app/features/book_upload/presentation/pages/book_edit_page.dart';
import 'package:korean_language_app/features/books/presentation/pages/book_search_page.dart';
import 'package:korean_language_app/features/books/presentation/pages/pdf_viewer_page.dart';
import 'package:korean_language_app/features/books/presentation/widgets/book_detail_bottomsheet.dart';
import 'package:korean_language_app/features/books/presentation/widgets/book_grid.dart';
import 'package:korean_language_app/features/books/presentation/widgets/book_grid_skeleton.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();
  bool _isRefreshing = false;
  final Map<String, bool> _editPermissionCache = {};
  bool _isInitialized = false;
  
  KoreanBooksCubit get _koreanBooksCubit => context.read<KoreanBooksCubit>();
  FavoriteBooksCubit get _favoriteBooksCubit => context.read<FavoriteBooksCubit>();
  LanguagePreferenceCubit get _languageCubit => context.read<LanguagePreferenceCubit>();
  FileUploadCubit get _fileUploadCubit => context.read<FileUploadCubit>();
  SnackBarCubit get _snackBarCubit => context.read<SnackBarCubit>();

  StreamSubscription<KoreanBooksState>? _pdfLoadingSubscription;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
    );
    
    // Initialize with delay to allow widget tree to be built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _koreanBooksCubit.loadInitialBooks();
      _favoriteBooksCubit.loadInitialBooks();
      context.read<ConnectivityCubit>().checkConnectivity();
      setState(() {
        _isInitialized = true;
      });
    });
    
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _pdfLoadingSubscription?.cancel();
    super.dispose();
  }
  
  void _onScroll() {
    if (_isNearBottom && !_isRefreshing) {
      final state = _koreanBooksCubit.state;
      
      if (state.hasMore && !state.currentOperation.isInProgress) {
        _koreanBooksCubit.loadMoreBooks();
      }
    }
  }
  
  bool get _isNearBottom {
    if (!_scrollController.hasClients) return false;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
  
  void _toggleFavorite(BookItem book) {
    _favoriteBooksCubit.toggleFavorite(book);
  }
  
  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    
    try {
      await _koreanBooksCubit.hardRefresh();
      await _favoriteBooksCubit.hardRefresh();
      _editPermissionCache.clear();
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  Future<bool> _checkEditPermission(String bookId) async {
    if (_editPermissionCache.containsKey(bookId)) {
      return _editPermissionCache[bookId]!;
    }
    
    final hasPermission = await _koreanBooksCubit.canUserEditBook(bookId);
    _editPermissionCache[bookId] = hasPermission;
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
      appBar: _buildAppBar(theme, colorScheme),
      body: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, connectivityState) {
          final bool isOffline = connectivityState is ConnectivityDisconnected;
          
          return Column(
            children: [
              // Connectivity status banner
              if (isOffline)
                ErrorView(
                  message: '',
                  errorType: FailureType.network,
                  onRetry: () {
                    context.read<ConnectivityCubit>().checkConnectivity();
                  },
                  isCompact: true,
                ),
              
              _buildCategoryTabs(theme),
              Expanded(
                child: _buildTabBarView(isOffline),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.uploadBooks),
        tooltip: _languageCubit.getLocalizedText(
          korean: '책 업로드',
          english: 'Upload Book',
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  AppBar _buildAppBar(ThemeData theme, ColorScheme colorScheme) {
    return AppBar(
      title: Text(
        _languageCubit.getLocalizedText(
          korean: '책',
          english: 'Books',
        ),
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      elevation: 0,
      backgroundColor: colorScheme.surface,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearchDelegate(),
        ),
        IconButton(
          icon: const Icon(Icons.favorite),
          onPressed: () {
            context.push(Routes.favoriteBooks); 
          },
          tooltip: _languageCubit.getLocalizedText(
            korean: '즐겨찾기',
            english: 'Favorites',
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategoryTabs(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues( alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withValues( alpha: 0.7),
        labelStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: theme.textTheme.titleSmall,
        indicatorColor: theme.colorScheme.primary,
        tabs: [
          _buildTabWithIcon(
            CourseCategory.korean.getFlagAsset(),
            _languageCubit.getLocalizedText(
              korean: '한국어',
              english: 'Korean',
            ),
          ),
          _buildTabWithIcon(
            CourseCategory.nepali.getFlagAsset(),
            _languageCubit.getLocalizedText(
              korean: '네팔어',
              english: 'Nepali',
            ),
          ),
          _buildTabWithIcon(
            CourseCategory.test.getFlagAsset(),
            _languageCubit.getLocalizedText(
              korean: '시험',
              english: 'Tests',
            ),
          ),
          _buildTabWithIcon(
            CourseCategory.global.getFlagAsset(),
            _languageCubit.getLocalizedText(
              korean: '글로벌',
              english: 'Global',
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabWithIcon(String flagAsset, String text) {
    return Tab(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              flagAsset,
              width: 20,
              height: 20,
              errorBuilder: (ctx, error, stackTrace) => const Icon(
                Icons.public,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
  
  Widget _buildTabBarView(bool isOffline) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildBooksGridView(CourseCategory.korean, isOffline),
        _buildBooksGridView(CourseCategory.nepali, isOffline),
        _buildBooksGridView(CourseCategory.test, isOffline),
        _buildBooksGridView(CourseCategory.global, isOffline),
      ],
    );
  }
  
  Widget _buildBooksGridView(CourseCategory category, bool isOffline) {
    if (category == CourseCategory.korean) {
      return _buildKoreanBooksGrid(isOffline);
    }
    
    return Center(
      child: Text(
        _languageCubit.getLocalizedText(
          korean: '${category.name} 섹션 - 곧 제공될 예정입니다',
          english: '${category.name} section - coming soon',
        ),
      ),
    );
  }
  
  Widget _buildKoreanBooksGrid(bool isOffline) {
    return BlocConsumer<KoreanBooksCubit, KoreanBooksState>(
      listener: (context, state) {
        final operation = state.currentOperation;
        
        if (operation.status == KoreanBooksOperationStatus.failed) {
          if (operation.type != KoreanBooksOperationType.loadPdf) {
            String errorMessage = operation.message ?? 'Operation failed';
            
            switch (operation.type) {
              case KoreanBooksOperationType.loadBooks:
                errorMessage = 'Failed to load books';
                break;
              case KoreanBooksOperationType.loadMoreBooks:
                errorMessage = 'Failed to load more books';
                break;
              case KoreanBooksOperationType.searchBooks:
                errorMessage = 'Failed to search books';
                break;
              case KoreanBooksOperationType.refreshBooks:
                errorMessage = 'Failed to refresh books';
                break;
              default:
                break;
            }
            
            _snackBarCubit.showErrorLocalized(
              korean: errorMessage,
              english: errorMessage,
            );
          }
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
                _koreanBooksCubit.loadInitialBooks();
              }
            },
          );
        }
        
        // If loading and no data, show loading skeleton
        if (state.isLoading && state.books.isEmpty) {
          return const BookGridSkeleton();
        }
        
        // If error and no data, show error message with retry button
        if (state.hasError && state.books.isEmpty) {
          return ErrorView(
            message: state.error ?? '',
            errorType: state.errorType,
            onRetry: () {
              _koreanBooksCubit.loadInitialBooks();
            },
          );
        }
        
        // Show books content (with error banner if there's an error but we have data)
        return _buildBooksContent(state, isOffline);
      },
    );
  }
  
  Widget _buildBooksContent(KoreanBooksState state, bool isOffline) {
    if (state.books.isEmpty) {
      return _buildEmptyBooksView(CourseCategory.korean);
    }
    
    final isLoadingMore = state.currentOperation.type == KoreanBooksOperationType.loadMoreBooks && 
                         state.currentOperation.isInProgress;
    
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
                _koreanBooksCubit.loadInitialBooks();
              },
              isCompact: true,
            ),
          
          Expanded(
            child: Stack(
              children: [
                BooksGrid(
                  books: state.books,
                  scrollController: _scrollController,
                  checkEditPermission: _checkEditPermission,
                  onViewClicked: _viewPdf,
                  onTestClicked: _testBook,
                  onToggleFavorite: _toggleFavorite,
                  onEditClicked: _editBook,
                  onDeleteClicked: _deleteBook,
                  onInfoClicked: _showBookDetails,
                  onDownloadClicked: _showDownloadOptions,
                ),
                if (isLoadingMore)
                  const Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyBooksView(CourseCategory category) {
    return RefreshIndicator(
      onRefresh: () async {
        await _refreshData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              const Icon(
                Icons.book_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _languageCubit.getLocalizedText(
                  korean: '${category.name} 책이 없습니다',
                  english: 'No ${category.name} books available',
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _languageCubit.getLocalizedText(
                  korean: '새 책을 추가하려면 + 버튼을 누르세요',
                  english: 'Tap the + button to add new books',
                ),
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showSearchDelegate() {
    showSearch(
      context: context,
      delegate: BookSearchDelegate(
        koreanBooksCubit: _koreanBooksCubit,
        favoriteBooksCubit: _favoriteBooksCubit,
        languageCubit: _languageCubit,
        onToggleFavorite: _toggleFavorite,
        onViewPdf: _viewPdf,
        onEditBook: _editBook,
        onDeleteBook: _deleteBook,
        checkEditPermission: _checkEditPermission,
        onInfoClicked: _showBookDetails,
        onDownloadClicked: _showDownloadOptions,
      ),
    );
  }
  
  void _showDownloadOptions(BookItem book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Book'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose download format:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF Format'),
              subtitle: Text('${book.title}.pdf'),
              onTap: () {
                Navigator.pop(context);
                _snackBarCubit.showInfoLocalized(
                  korean: '${book.title} PDF를 다운로드 중...',
                  english: 'Downloading ${book.title} as PDF...',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('Save for offline'),
              subtitle: const Text('Download for offline viewing'),
              onTap: () {
                Navigator.pop(context);
                _snackBarCubit.showInfoLocalized(
                  korean: '${book.title}을(를) 오프라인용으로 저장 중...',
                  english: 'Saving ${book.title} for offline use...',
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
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
  
  void _testBook(BookItem book) {
    _snackBarCubit.showInfoLocalized(
      korean: '테스트 기능이 곧 제공될 예정입니다',
      english: 'Test functionality coming soon',
    );
  }

  void _showBookDetails(BookItem book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BookDetailsBottomSheet(book: book),
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
      extra: BookEditPage(book: book),
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
          style: const TextStyle(fontWeight: FontWeight.bold),
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
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: Text(
              _languageCubit.getLocalizedText(
                korean: '취소',
                english: 'CANCEL',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
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
  
  Widget _buildPdfLoadingDialog(String title) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _languageCubit.getLocalizedText(
              korean: '"$title" 로딩 중...',
              english: 'Loading "$title"...',
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
      extra: PDFViewerScreen(pdfFile: pdfFile, title: title),
    );
  }
}