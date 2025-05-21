import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      return Center(
        child: Text(
          languageCubit.getLocalizedText(
            korean: '검색어는 2자 이상이어야 합니다',
            english: 'Search term must be at least 2 characters',
          ),
        ),
      );
    }
    
    koreanBooksCubit.searchBooks(query);
    
    return BlocBuilder<KoreanBooksCubit, KoreanBooksState>(
      builder: (context, state) {
        if (state is KoreanBooksLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is KoreanBooksError) {
          return Center(child: Text("Error: ${state.message}"));
        } else if (state is KoreanBooksLoaded) {
          final books = state.books;
          
          if (books.isEmpty) {
            return Center(
              child: Text(
                languageCubit.getLocalizedText(
                  korean: '검색 결과가 없습니다',
                  english: 'No results found',
                ),
              ),
            );
          }
          
          return ListView.builder(
            itemCount: books.length,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemBuilder: (context, index) {
              final book = books[index];
              
              return BlocBuilder<FavoriteBooksCubit, FavoriteBooksState>(
                builder: (context, favoritesState) {
                  bool isFavorite = false;
                  if (favoritesState is FavoriteBooksLoaded) {
                    isFavorite = favoritesState.books.any((favBook) => favBook.id == book.id);
                  }
                  
                  return FutureBuilder<bool>(
                    future: checkEditPermission(book.id),
                    builder: (context, snapshot) {
                      final canEdit = snapshot.data ?? false;
                      
                      // Use our new BookListCard widget
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
        }
        
        return const Center(child: Text("Search books..."));
      },
    );
  }
  
  @override
  Widget buildSuggestions(BuildContext context) {
    // Don't search for suggestions if query is too short
    if (query.length < 2) {
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
    
    // Search as user types
    koreanBooksCubit.searchBooks(query);
    
    return buildResults(context);
  }
}