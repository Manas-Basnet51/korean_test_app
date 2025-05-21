import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/features/books/presentation/bloc/favorite_books/favorite_books_cubit.dart';
import 'package:korean_language_app/features/books/presentation/bloc/korean_books/korean_books_cubit.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';
import 'package:korean_language_app/features/books/presentation/widgets/book_list_card.dart';

class BookSearchDelegate extends SearchDelegate<BookItem?> {
  final KoreanBooksCubit koreanBooksCubit;
  final FavoriteBooksCubit favoriteBooksCubit;
  final LanguagePreferenceCubit languageCubit;
  final Function(BookItem) onToggleFavorite;
  final Function(BookItem) onViewPdf;
  final Function(BookItem)? onEditBook;
  final Function(BookItem)? onDeleteBook;
  final Function(BookItem)? onQuizBook;
  final Future<bool> Function(String) checkEditPermission;
  final Function(BookItem)? onInfoClicked;
  final Function(BookItem)? onDownloadClicked;
  
  BookSearchDelegate({
    required this.koreanBooksCubit,
    required this.favoriteBooksCubit,
    required this.languageCubit,
    required this.onToggleFavorite,
    required this.onViewPdf,
    this.onEditBook,
    this.onDeleteBook,
    this.onQuizBook,
    required this.checkEditPermission,
    required this.onInfoClicked,
    required this.onDownloadClicked,
  });
  
  @override
  String get searchFieldLabel => languageCubit.getLocalizedText(
    korean: '책 검색',
    english: 'Search books',
  );
  
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          koreanBooksCubit.loadInitialBooks();
        },
      ),
    ];
  }
  
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        koreanBooksCubit.loadInitialBooks();
        close(context, null);
      },
    );
  }
  
  @override
  Widget buildResults(BuildContext context) {
    if (query.length < 2) {
      return _buildMinimumQueryMessage();
    }
    
    koreanBooksCubit.searchBooks(query);
    
    return BlocBuilder<KoreanBooksCubit, KoreanBooksState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.hasError) {
          return _buildErrorView(context, state.error!, state.errorType!);
        }
        
        if (state.books.isEmpty) {
          return _buildNoResultsView();
        }
        
        return ListView.builder(
          itemCount: state.books.length,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          itemBuilder: (context, index) {
            final book = state.books[index];
            
            return BlocBuilder<FavoriteBooksCubit, FavoriteBooksState>(
              builder: (context, favoritesState) {
                bool isFavorite = favoritesState.books.any((favBook) => favBook.id == book.id);
                
                return FutureBuilder<bool>(
                  future: checkEditPermission(book.id),
                  builder: (context, snapshot) {
                    final canEdit = snapshot.data ?? false;
                    
                    return BookListCard(
                      book: book,
                      isFavorite: isFavorite,
                      canEdit: canEdit,
                      onToggleFavorite: onToggleFavorite,
                      onViewPdf: onViewPdf,
                      onEditBook: onEditBook,
                      onDeleteBook: onDeleteBook,
                      onQuizBook: onQuizBook,
                      onInfoClicked: onInfoClicked,
                      onDownloadClicked: onDownloadClicked,
                    );
                  }
                );
              },
            );
          },
        );
      },
    );
  }
  
  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 2) {
      return _buildInitialSearchView();
    }
    
    koreanBooksCubit.searchBooks(query);
    return buildResults(context);
  }

  Widget _buildInitialSearchView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            languageCubit.getLocalizedText(
              korean: '검색어를 입력하세요',
              english: 'Enter search terms',
            ),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimumQueryMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            languageCubit.getLocalizedText(
              korean: '검색어는 2자 이상이어야 합니다',
              english: 'Search term must be at least 2 characters',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            languageCubit.getLocalizedText(
              korean: '검색 결과가 없습니다',
              english: 'No results found',
            ),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"$query"',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message, FailureType type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getErrorIcon(type),
            size: 64,
            color: _getErrorColor(context, type),
          ),
          const SizedBox(height: 16),
          Text(
            _getErrorTitle(type),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => koreanBooksCubit.searchBooks(query),
            icon: const Icon(Icons.refresh),
            label: Text(
              languageCubit.getLocalizedText(
                korean: '다시 시도',
                english: 'Try Again',
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getErrorIcon(FailureType type) {
    switch (type) {
      case FailureType.network:
        return Icons.wifi_off;
      case FailureType.server:
        return Icons.cloud_off;
      case FailureType.auth:
        return Icons.lock;
      case FailureType.permission:
        return Icons.no_accounts;
      default:
        return Icons.error_outline;
    }
  }

  Color _getErrorColor(BuildContext context, FailureType type) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case FailureType.network:
        return Colors.orange;
      case FailureType.server:
        return Colors.red;
      case FailureType.auth:
        return colorScheme.primary;
      case FailureType.permission:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getErrorTitle(FailureType type) {
    return languageCubit.getLocalizedText(
      korean: _getErrorTitleKorean(type),
      english: _getErrorTitleEnglish(type),
    );
  }

  String _getErrorTitleKorean(FailureType type) {
    switch (type) {
      case FailureType.network:
        return '인터넷 연결 없음';
      case FailureType.server:
        return '서버 오류';
      case FailureType.auth:
        return '인증 필요';
      case FailureType.permission:
        return '권한 없음';
      default:
        return '오류가 발생했습니다';
    }
  }

  String _getErrorTitleEnglish(FailureType type) {
    switch (type) {
      case FailureType.network:
        return 'No Internet Connection';
      case FailureType.server:
        return 'Server Error';
      case FailureType.auth:
        return 'Authentication Required';
      case FailureType.permission:
        return 'Permission Denied';
      default:
        return 'Something Went Wrong';
    }
  }
}