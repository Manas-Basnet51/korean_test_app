import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:korean_language_app/core/routes/app_router.dart';
import 'package:korean_language_app/core/enums/course_category.dart';
import 'package:korean_language_app/features/books/presentation/bloc/favorite_books/favorite_books_cubit.dart';
import 'package:korean_language_app/features/books/presentation/bloc/korean_books/korean_books_cubit.dart';
import 'package:korean_language_app/features/book_upload/presentation/bloc/file_upload_cubit.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';
import 'package:korean_language_app/features/books/presentation/pages/book_edit_page.dart';
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
  
  KoreanBooksCubit get _koreanBooksCubit => context.read<KoreanBooksCubit>();
  FavoriteBooksCubit get _favoriteBooksCubit => context.read<FavoriteBooksCubit>();
  LanguagePreferenceCubit get _languageCubit => context.read<LanguagePreferenceCubit>();
  FileUploadCubit get _fileUploadCubit => context.read<FileUploadCubit>();

  StreamSubscription<KoreanBooksState>? _pdfLoadingSubscription;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4, // Korean, Nepali, Test, Global
      vsync: this,
    );
    _koreanBooksCubit.loadInitialBooks();
    _favoriteBooksCubit.loadInitialBooks();
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
      
      if (state is KoreanBooksLoaded && state.hasMore) {
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
      _editPermissionCache.clear(); // Clear permission cache on refresh
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  Future<bool> _checkEditPermission(String bookId) async {
    // Check cache first
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
    
    return Scaffold(
      appBar: _buildAppBar(theme, colorScheme),
      body: Column(
        children: [
          _buildCategoryTabs(theme),
          Expanded(
            child: _buildTabBarView(),
          ),
        ],
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
  
  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Korean Books
        _buildBooksGridView(CourseCategory.korean),
        
        // Nepali Books
        _buildBooksGridView(CourseCategory.nepali),
        
        // Test Books
        _buildBooksGridView(CourseCategory.test),
        
        // Global Books
        _buildBooksGridView(CourseCategory.global),
      ],
    );
  }
  
  Widget _buildBooksGridView(CourseCategory category) {
    if (category == CourseCategory.korean) {
      return _buildKoreanBooksGrid();
    }
    
    // Placeholder for other categories - to be implemented
    return Center(
      child: Text(
        _languageCubit.getLocalizedText(
          korean: '${category.name} 섹션 - 곧 제공될 예정입니다',
          english: '${category.name} section - coming soon',
        ),
      ),
    );
  }
  
  Widget _buildKoreanBooksGrid() {
    return BlocBuilder<KoreanBooksCubit, KoreanBooksState>(
      builder: (context, state) {
        if (state is KoreanBooksInitial) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is KoreanBooksError) {
          return _buildErrorView(state.message);
        }
        
        List<BookItem> books = [];
        bool isLoading = false;
        
        if (state is KoreanBooksLoaded) {
          books = state.books;
        } else if (state is KoreanBooksLoadingMore) {
          books = state.currentBooks;
          isLoading = true;
        } else if (state is KoreanBookPdfLoading) {
          books = state.books;
        } else if (state is KoreanBookPdfLoaded) {
          books = state.books;
        } else if (state is KoreanBookPdfError) {
          books = state.books;
        } else if (state is KoreanBooksLoading) {
          return const BookGridSkeleton();
        }
        
        // Check FileUploadCubit state to show appropriate loading states
        final fileUploadState = context.watch<FileUploadCubit>().state;
        if (fileUploadState is FileUploading) {
          isLoading = true;
        }
        
        if (books.isEmpty) {
          return _buildEmptyBooksView(CourseCategory.korean);
        }
        
        return RefreshIndicator(
          onRefresh: _refreshData,
          child: Stack(
            children: [
              BooksGrid(
                books: books,
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
              if (isLoading)
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
        );
      },
    );
  }
  
  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _languageCubit.getLocalizedText(
              korean: '오류가 발생했습니다',
              english: 'An error occurred',
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: Text(
              _languageCubit.getLocalizedText(
                korean: '다시 시도',
                english: 'Try Again',
              ),
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
                // Implement PDF download
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Downloading ${book.title} as PDF...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('Save for offline'),
              subtitle: const Text('Download for offline viewing'),
              onTap: () {
                Navigator.pop(context);
                // Implement offline saving logic
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saving ${book.title} for offline use...')),
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
  
  // PDF viewing functionality
  void _viewPdf(BookItem book) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildPdfLoadingDialog(book.title),
    );
    
    context.read<KoreanBooksCubit>().loadBookPdf(book.id);
    
    _listenForPdfLoadingResult(book);
  }
  
  // Placeholder for test book functionality - to be implemented
  void _testBook(BookItem book) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _languageCubit.getLocalizedText(
            korean: '테스트 기능이 곧 제공될 예정입니다',
            english: 'Test functionality coming soon',
          ),
        ),
      ),
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
      // ignore: use_build_context_synchronously //TODO: have a dedicated snackbar system
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _languageCubit.getLocalizedText(
              korean: '이 책을 편집할 권한이 없습니다',
              english: 'You do not have permission to edit this book',
            ),
          ),
        ),
      );
      return;
    }

    // ignore: use_build_context_synchronously //TODO: what?
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
      // ignore: use_build_context_synchronously //TODO: have a dedicated snackbar system
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _languageCubit.getLocalizedText(
              korean: '이 책을 삭제할 권한이 없습니다',
              english: 'You do not have permission to delete this book',
            ),
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      // ignore: use_build_context_synchronously //TODO: what??
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
        // ignore: use_build_context_synchronously //TODO: have a dedicated snackbar system
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _languageCubit.getLocalizedText(
                korean: '책이 성공적으로 삭제되었습니다',
                english: 'Book deleted successfully',
              ),
            ),
          ),
        );
      } else { 
        // ignore: use_build_context_synchronously //TODO: have a dedicated snackbar system
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _languageCubit.getLocalizedText(
                korean: '책 삭제에 실패했습니다',
                english: 'Failed to delete book',
              ),
            ),
          ),
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
      if (state is KoreanBookPdfLoaded && state.bookId == book.id) {

        // ignore: use_build_context_synchronously // TODO: what??
        Navigator.of(context, rootNavigator: true).pop();
        _verifyAndOpenPdf(state.pdfFile, book.title);
        _pdfLoadingSubscription?.cancel();
        _pdfLoadingSubscription = null;

      } else if (state is KoreanBookPdfError && state.bookId == book.id) {
        // ignore: use_build_context_synchronously //TODO: whatt??
        Navigator.of(context, rootNavigator: true).pop();
        _showRetrySnackBar(
          _getReadableErrorMessage(state.message), 
          () => _viewPdf(book),
        );

        _pdfLoadingSubscription?.cancel();
        _pdfLoadingSubscription = null;

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: _languageCubit.getLocalizedText(
            korean: '다시 시도',
            english: 'Retry',
          ),
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
        SnackBar(
          content: Text(
            _languageCubit.getLocalizedText(
              korean: '오류: PDF 파일을 열 수 없습니다',
              english: 'Error: PDF file cannot be opened',
            ),
          ),
        ),
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



