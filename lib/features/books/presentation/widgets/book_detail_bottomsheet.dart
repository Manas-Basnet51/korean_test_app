

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:korean_language_app/core/enums/book_level.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';
class BookDetailsBottomSheet extends StatelessWidget {
  final BookItem book;

  const BookDetailsBottomSheet({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 16),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues( alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              
              // Book header section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildBookHeader(context, theme),
              ),
              
              // Details
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Description
                    Text(
                      'Description',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    
                    // Details grid
                    _buildDetailsGrid(context, theme),
                    const SizedBox(height: 24),
                    
                    // Metadata
                    _buildMetadataSection(context, theme),
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    _buildActionButtons(context, colorScheme),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookHeader(BuildContext context, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Book cover thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: book.bookImage != null && book.bookImage!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: book.bookImage!,
                  width: 100,
                  height: 140,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildCoverPlaceholder(context),
                  errorWidget: (context, url, error) => _buildCoverPlaceholder(context),
                )
              : _buildCoverPlaceholder(context),
        ),
        const SizedBox(width: 16),
        
        // Book info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    book.icon,
                    size: 16,
                    color: theme.colorScheme.primary.withValues( alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      book.category,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues( alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildLevelChip(context, theme),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues( alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    book.duration,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues( alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.menu_book_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues( alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${book.chaptersCount} chapter${book.chaptersCount != 1 ? 's' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues( alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoverPlaceholder(BuildContext context) {
    return Container(
      width: 100,
      height: 140,
      color: Theme.of(context).colorScheme.primary.withValues( alpha: 0.1),
      child: Center(
        child: Icon(
          book.icon,
          size: 40,
          color: Theme.of(context).colorScheme.primary.withValues( alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildLevelChip(BuildContext context, ThemeData theme) {
    final levelColor = book.level.getColor();
    final levelName = book.level.toString().split('.').last;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: levelColor.withValues( alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: levelColor.withValues( alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart,
            size: 14,
            color: levelColor,
          ),
          const SizedBox(width: 6),
          Text(
            levelName,
            style: TextStyle(
              color: levelColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid(BuildContext context, ThemeData theme) {
    final List<Map<String, dynamic>> details = [
      {
        'icon': Icons.language,
        'label': 'Country',
        'value': book.country,
      },
      {
        'icon': Icons.category,
        'label': 'Category',
        'value': book.courseCategory.toString().split('.').last,
      },
      {
        'icon': Icons.timer,
        'label': 'Duration',
        'value': book.duration,
      },
      {
        'icon': Icons.menu_book,
        'label': 'Chapters',
        'value': '${book.chaptersCount}',
      },
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: details.length,
      itemBuilder: (context, index) {
        final detail = details[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues( alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    detail['icon'],
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    detail['label'],
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues( alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                detail['value'],
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetadataSection(BuildContext context, ThemeData theme) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues( alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metadata',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          if (book.createdAt != null) _buildMetadataItem(
            context,
            Icons.calendar_today,
            'Created',
            dateFormat.format(book.createdAt!),
            theme,
          ),
          
          if (book.updatedAt != null) _buildMetadataItem(
            context,
            Icons.update,
            'Updated',
            dateFormat.format(book.updatedAt!),
            theme,
          ),
          
          if (book.creatorUid != null) _buildMetadataItem(
            context,
            Icons.person,
            'Creator ID',
            book.creatorUid!,
            theme,
          ),
          
          if (book.pdfPath != null) _buildMetadataItem(
            context,
            Icons.insert_drive_file,
            'PDF Path',
            book.pdfPath!,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurface.withValues( alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues( alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Implement view action
            },
            icon: const Icon(Icons.menu_book),
            label: const Text('Read Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            // Implement download action
          },
          icon: const Icon(Icons.download),
          label: const Text('Download'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: colorScheme.primary.withValues( alpha: 0.5)),
          ),
        ),
      ],
    );
  }
}