import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:korean_language_app/core/enums/book_level.dart';
import 'package:korean_language_app/core/models/test_item.dart';

class TestCard extends StatelessWidget {
  final TestItem test;
  final bool canEdit;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewDetails;

  const TestCard({
    super.key,
    required this.test,
    required this.canEdit,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 3,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with image or icon
                Expanded(
                  flex: 3,
                  child: _buildHeader(context),
                ),
                
                // Content
                Expanded(
                  flex: 4,
                  child: _buildContent(context, theme),
                ),
              ],
            ),
            
            // Top badges and options
            _buildTopOverlay(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    if (test.imageUrl != null && test.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: test.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildHeaderPlaceholder(theme),
        errorWidget: (context, url, error) => _buildHeaderPlaceholder(theme),
      );
    } else {
      return _buildHeaderPlaceholder(theme);
    }
  }

  Widget _buildHeaderPlaceholder(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.8),
            theme.colorScheme.primary.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          test.icon,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            test.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // Questions count and time
          Row(
            children: [
              Icon(
                Icons.quiz,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '${test.questionCount} Q',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.timer,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                test.formattedTimeLimit,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Description
          Expanded(
            child: Text(
              test.description,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Bottom info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Level chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: test.level.getColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: test.level.getColor().withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  test.level.toString().split('.').last,
                  style: TextStyle(
                    color: test.level.getColor(),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
              
              // Category
              Text(
                test.category.name,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopOverlay(BuildContext context, ThemeData theme) {
    return Positioned(
      top: 8,
      right: 8,
      left: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Passing score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              'Pass: ${test.passingScore}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Options menu
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            child: PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              onSelected: (value) => _handleMenuAction(context, value),
              itemBuilder: (context) => _buildMenuItems(context),
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuItem<String>> _buildMenuItems(BuildContext context) {
    final List<PopupMenuItem<String>> menuItems = [
      const PopupMenuItem<String>(
        value: 'start',
        child: Row(
          children: [
            Icon(Icons.play_arrow, size: 18),
            SizedBox(width: 8),
            Text('Start Test'),
          ],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'details',
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18),
            SizedBox(width: 8),
            Text('View Details'),
          ],
        ),
      ),
    ];
    
    // Add edit/delete options if user has permission
    if (canEdit) {
      if (onEdit != null) {
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
      
      if (onDelete != null) {
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
      case 'start':
        onTap();
        break;
      case 'details':
        if (onViewDetails != null) onViewDetails!();
        break;
      case 'edit':
        if (onEdit != null) onEdit!();
        break;
      case 'delete':
        if (onDelete != null) onDelete!();
        break;
    }
  }
}