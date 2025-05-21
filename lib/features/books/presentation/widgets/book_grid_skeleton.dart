import 'package:flutter/material.dart';

class BookGridSkeleton extends StatelessWidget {
  const BookGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: 6, // Show 6 skeleton items while loading
      itemBuilder: (context, index) {
        return const BookCardSkeleton();
      },
    );
  }
}

class BookCardSkeleton extends StatelessWidget {
  const BookCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 3,
      shadowColor: colorScheme.shadow.withValues( alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full card image placeholder
          Container(
            color: Colors.grey.withValues( alpha: 0.2),
          ),
          
          // Top options placeholders
          Positioned(
            top: 8,
            right: 8,
            left: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Level badge placeholder
                Container(
                  height: 24,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues( alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                
                // Menu icon placeholder
                Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues( alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom title overlay placeholder
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.grey.withValues( alpha: 0.3),
                  ],
                ),
              ),
              child: Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues( alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          
          // View button placeholder
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              height: 32,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.grey.withValues( alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          
          // Favorite button placeholder
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: Colors.grey.withValues( alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}