import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:korean_language_app/core/enums/book_level.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';
import 'package:korean_language_app/features/books/presentation/widgets/favorite_button.dart';

class BookListCard extends StatelessWidget {
  final BookItem book;
  final bool isFavorite;
  final bool canEdit;
  final Function(BookItem) onToggleFavorite;
  final Function(BookItem) onViewPdf;
  final Function(BookItem)? onEditBook;
  final Function(BookItem)? onDeleteBook;
  final Function(BookItem)? onQuizBook;
  final Function(BookItem)? onInfoClicked;
  final Function(BookItem)? onDownloadClicked;

  const BookListCard({
    super.key,
    required this.book,
    required this.isFavorite,
    required this.canEdit,
    required this.onToggleFavorite,
    required this.onViewPdf,
    this.onEditBook,
    this.onDeleteBook,
    this.onQuizBook,
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onViewPdf(book),
        child: SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Book cover image section (left side)
              _buildCoverSection(context, theme),
              
              // Book details section (right side)
              _buildDetailsSection(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverSection(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: 110,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Book cover
            _buildCoverImage(context),
            
            // Badges and indicators
            _buildCoverBadges(theme),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCoverImage(BuildContext context) {
    final hasImage = book.bookImage != null && book.bookImage!.isNotEmpty;
    
    return hasImage
        ? CachedNetworkImage(
            imageUrl: book.bookImage!,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildImagePlaceholder(context),
            errorWidget: (context, url, error) => _buildImagePlaceholder(context),
          )
        : _buildImagePlaceholder(context);
  }
  
  Widget _buildImagePlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    final placeholderColor = theme.colorScheme.primary.withValues( alpha: 0.1);
    final iconColor = theme.colorScheme.primary.withValues( alpha: 0.7);
    
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
                  color: theme.colorScheme.primary,
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

  Widget _buildCoverBadges(ThemeData theme) {
    return Stack(
      children: [
        // Favorite button
        Positioned(
          top: 8,
          left: 8,
          child: AnimatedFavoriteButton(
            isFavorite: isFavorite,
            onPressed: () => onToggleFavorite(book),
            size: 16,
          ),
        ),
        
        // Admin/Edit indicator (if user has permission)
        if (canEdit)
          Positioned(
            top: 8,
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
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
          
        // PDF indicator
        Positioned(
          bottom: 36,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues( alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  size: 12,
                  color: Colors.white,
                ),
                SizedBox(width: 2),
                Text(
                  'PDF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Level indicator
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
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
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context, ThemeData theme) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title area with overflow handling
            Row(
              children: [
                Expanded(
                  child: Text(
                    book.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Menu button
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  padding: EdgeInsets.zero,
                  onSelected: (value) => _handleMenuAction(context, value),
                  itemBuilder: (context) => _buildMenuItems(context),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Duration info - small and compact
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  book.duration,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 6),
            
            // Description with flexible area
            Expanded(
              child: Text(
                book.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Action buttons in a better layout
            _buildActionButtons(context, theme),
          ],
        ),
      ),
    );
  }
  
  List<PopupMenuItem<String>> _buildMenuItems(BuildContext context) {
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
    if (canEdit) {
      if (onEditBook != null) {
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
      }
      
      if (onDeleteBook != null) {
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
    }
    
    return menuItems;
  }
  
  void _handleMenuAction(BuildContext context, String value) {
    switch (value) {
      case 'view':
        onViewPdf(book);
        break;
      case 'test':
        if (onQuizBook != null) onQuizBook!(book);
        break;
      case 'info':
        if(onInfoClicked != null) onInfoClicked!(book);
        break;
      case 'download':
        if(onDownloadClicked != null) onDownloadClicked!(book);
        break;
      case 'edit':
        if (onEditBook != null) onEditBook!(book);
        break;
      case 'delete':
        if (onDeleteBook != null) _confirmDelete(context);
        break;
    }
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Primary button
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.menu_book, size: 14),
            label: const Text(
              'Read',
              style: TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 6),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            onPressed: () => onViewPdf(book),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Secondary actions
        if (canEdit && onEditBook != null)
          Expanded(
            child: _buildIconButton(
              context,
              Icons.edit,
              () => onEditBook!(book),
              theme.colorScheme.primary.withValues( alpha: 0.1),
              theme.colorScheme.primary,
            ),
          )
        else
          Expanded(
            child: _buildIconButton(
              context,
              Icons.quiz,
              onQuizBook != null ? () => onQuizBook!(book) : null,
              theme.colorScheme.secondary.withValues( alpha: 0.1),
              theme.colorScheme.secondary,
            ),
          ),
        
        const SizedBox(width: 8),
        
        // Download button
        Expanded(
          child: _buildIconButton(
            context,
            Icons.download,
            () => onDownloadClicked != null ? onDownloadClicked!(book) : null,
            Colors.green.withValues( alpha: 0.1),
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    IconData icon,
    VoidCallback? onPressed,
    Color backgroundColor,
    Color iconColor,
  ) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: SizedBox(
          height: 32,
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text(
          'Are you sure you want to delete "${book.title}"? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onDeleteBook != null) {
                onDeleteBook!(book);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}