
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';
import 'package:korean_language_app/features/books/presentation/bloc/favorite_books/favorite_books_cubit.dart';
import 'package:korean_language_app/features/books/presentation/widgets/book_grid_card.dart';

class BooksGrid extends StatelessWidget {  
  final List<BookItem> books;  
  final ScrollController scrollController;  
  final Future<bool> Function(String) checkEditPermission;  
  final Function(BookItem) onViewClicked;  
  final Function(BookItem) onTestClicked;  
  final Function(BookItem) onEditClicked;  
  final Function(BookItem) onDeleteClicked;
  final Function(BookItem) onToggleFavorite;
  final Function(BookItem) onInfoClicked;
  final Function(BookItem) onDownloadClicked;

  const BooksGrid({    
    super.key,    
    required this.books,    
    required this.scrollController,    
    required this.checkEditPermission,    
    required this.onViewClicked,    
    required this.onTestClicked,    
    required this.onEditClicked,    
    required this.onDeleteClicked,
    required this.onToggleFavorite,
    required this.onInfoClicked,
    required this.onDownloadClicked
  });  

  @override  
  Widget build(BuildContext context) {    
    return GridView.builder(      
      key: const PageStorageKey('books_grid'),      
      controller: scrollController,      
      padding: const EdgeInsets.all(16),      
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(        
        crossAxisCount: 2,        
        childAspectRatio: 0.75,        
        crossAxisSpacing: 16,        
        mainAxisSpacing: 20,      
      ),      
      itemCount: books.length,      
      itemBuilder: (context, index) {        
        final book = books[index];        
        return FutureBuilder<bool>(          
          future: checkEditPermission(book.id),          
          builder: (context, snapshot) {            
            final canEdit = snapshot.data ?? false;            
                        
            return BlocBuilder<FavoriteBooksCubit, FavoriteBooksState>(              
              builder: (context, favoritesState) {            
                    
                bool isFavorite = favoritesState.books.any((favBook) => favBook.id == book.id);          
                                
                return BookGridCard(                  
                  key: ValueKey(book.id),                  
                  book: book,                  
                  isFavorite: isFavorite,                  
                  showEditOptions: canEdit,                  
                  onViewClicked: () => onViewClicked(book),                  
                  onTestClicked: () => onTestClicked(book),                  
                  onEditClicked: canEdit ? () => onEditClicked(book) : null,                  
                  onDeleteClicked: canEdit ? () => onDeleteClicked(book) : null,
                  onToggleFavorite: () => onToggleFavorite(book),
                  onInfoClicked: () => onInfoClicked(book),
                  onDownloadClicked: () => onDownloadClicked(book),

                );
              },            
            );
          },        
        );
      },    
    );
  }
}