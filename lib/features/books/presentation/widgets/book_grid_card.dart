import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/enums/book_level.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';
import 'package:korean_language_app/features/books/presentation/bloc/korean_books/korean_books_cubit.dart';
import 'package:korean_language_app/features/books/presentation/widgets/favorite_button.dart';

class BookGridCard extends StatelessWidget {
  final BookItem book;
  final bool isFavorite;
  final bool showEditOptions;
  final VoidCallback onViewClicked;
  final VoidCallback onTestClicked;
  final VoidCallback? onEditClicked;
  final VoidCallback? onDeleteClicked;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onInfoClicked;
  final VoidCallback? onDownloadClicked;

  const BookGridCard({
    super.key,
    required this.book,
    required this.isFavorite,
    required this.onViewClicked,
    required this.onTestClicked,
    required this.onToggleFavorite,
    this.onEditClicked,
    this.onDeleteClicked,
    this.showEditOptions = false, 
    required this.onInfoClicked,
    required this.onDownloadClicked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 3,
      shadowColor: colorScheme.shadow.withValues( alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues( alpha: 0.1), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onViewClicked,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full card image
            _buildCoverImage(context),
            
            // Top options (menu and level badge)
            Positioned(
              top: 8,
              right: 8,
              left: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Level Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: book.level.getColor().withValues( alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      book.level.toString().split('.').last,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  
                  // Options menu with background
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(50),
                    child: PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues( alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'view':
                            onViewClicked();
                            break;
                          case 'test':
                            onTestClicked();
                            break;
                          case 'info':
                            if(onInfoClicked != null) onInfoClicked!();
                            break;
                          case 'download':
                            if(onDownloadClicked != null) onDownloadClicked!();
                            break;
                          case 'edit':
                            if (onEditClicked != null) onEditClicked!();
                            break;
                          case 'delete':
                            if (onDeleteClicked != null) onDeleteClicked!();
                            break;
                        }
                      },
                      itemBuilder: (context) {
                        final List<PopupMenuItem<String>> menuItems = [
                          const PopupMenuItem<String>(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.menu_book, size: 18),
                                SizedBox(width: 8),
                                Text('Open'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'test',
                            child: Row(
                              children: [
                                Icon(Icons.quiz, size: 18),
                                SizedBox(width: 8),
                                Text('Test'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'info',
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 18),
                                SizedBox(width: 8),
                                Text('Book Info'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'download',
                            child: Row(
                              children: [
                                Icon(Icons.download, size: 18),
                                SizedBox(width: 8),
                                Text('Download'),
                              ],
                            ),
                          ),
                        ];
                        
                        // Add edit/delete options if user has permission
                        if (showEditOptions) {
                          menuItems.add(const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ));
                          
                          menuItems.add(PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: Theme.of(context).colorScheme.error),
                                const SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                ),
                              ],
                            ),
                          ));
                        }
                        
                        return menuItems;
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Edit badge if user has edit permissions
            if (showEditOptions)
              Positioned(
                top: 48,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues( alpha: 0.85),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_note,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
          
            // Title overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues( alpha: 0.7),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        book.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AnimatedFavoriteButton(
                      isFavorite: isFavorite,
                      onPressed: onToggleFavorite,
                      size: 20,
                      useGradientBackground: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context) {
    return book.bookImage != null && book.bookImage!.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: book.bookImage!,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildImagePlaceholder(context),
            errorWidget: (context, url, error) {
              // Handle image error by attempting to regenerate the URL if possible
              _handleImageLoadError(context);
              return _buildImagePlaceholder(context);
            },
          )
        : _buildImagePlaceholder(context);
  }

  void _handleImageLoadError(BuildContext context) {
    if (book.bookImagePath != null && book.bookImagePath!.isNotEmpty) {
      // Only try to regenerate if we have a storage path
      context.read<KoreanBooksCubit>().regenerateBookImageUrl(book);
    }
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    final placeholderColor = Theme.of(context).colorScheme.primary.withValues( alpha: 0.1);
    final iconColor = Theme.of(context).colorScheme.primary.withValues( alpha: 0.7);
    
    return Container(
      color: placeholderColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              book.icon,
              size: 40,
              color: iconColor,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues( alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                book.title.length > 15 
                    ? '${book.title.substring(0, 15)}...' 
                    : book.title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}