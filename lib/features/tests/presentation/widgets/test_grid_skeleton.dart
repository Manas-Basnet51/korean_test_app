import 'package:flutter/material.dart';

class TestGridSkeleton extends StatelessWidget {
  const TestGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return const TestCardSkeleton();
      },
    );
  }
}

class TestCardSkeleton extends StatefulWidget {
  const TestCardSkeleton({super.key});

  @override
  State<TestCardSkeleton> createState() => _TestCardSkeletonState();
}

class _TestCardSkeletonState extends State<TestCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 3,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header skeleton
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: _getSkeletonColor(context, _animation.value),
                  ),
                  child: Stack(
                    children: [
                      // Top badges skeleton
                      Positioned(
                        top: 8,
                        right: 8,
                        left: 8,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: 20,
                              width: 60,
                              decoration: BoxDecoration(
                                color: _getSkeletonColor(context, _animation.value, isOverlay: true),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            Container(
                              height: 28,
                              width: 28,
                              decoration: BoxDecoration(
                                color: _getSkeletonColor(context, _animation.value, isOverlay: true),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Center icon placeholder
                      Center(
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: _getSkeletonColor(context, _animation.value, isOverlay: true),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Content skeleton
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title skeleton
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _getSkeletonColor(context, _animation.value),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 16,
                        width: 120,
                        decoration: BoxDecoration(
                          color: _getSkeletonColor(context, _animation.value),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Questions and time skeleton
                      Row(
                        children: [
                          Container(
                            height: 12,
                            width: 40,
                            decoration: BoxDecoration(
                              color: _getSkeletonColor(context, _animation.value),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            height: 12,
                            width: 50,
                            decoration: BoxDecoration(
                              color: _getSkeletonColor(context, _animation.value),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Description skeleton
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 12,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: _getSkeletonColor(context, _animation.value),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 12,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: _getSkeletonColor(context, _animation.value),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 12,
                              width: 80,
                              decoration: BoxDecoration(
                                color: _getSkeletonColor(context, _animation.value),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Bottom info skeleton
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 20,
                            width: 60,
                            decoration: BoxDecoration(
                              color: _getSkeletonColor(context, _animation.value),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          Container(
                            height: 12,
                            width: 40,
                            decoration: BoxDecoration(
                              color: _getSkeletonColor(context, _animation.value),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getSkeletonColor(BuildContext context, double animationValue, {bool isOverlay = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isOverlay) {
      if (isDark) {
        return Color.lerp(
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.2),
          animationValue,
        )!;
      } else {
        return Color.lerp(
          Colors.black.withValues(alpha: 0.1),
          Colors.black.withValues(alpha: 0.2),
          animationValue,
        )!;
      }
    }
    
    if (isDark) {
      return Color.lerp(
        Colors.grey[800]!,
        Colors.grey[700]!,
        animationValue,
      )!;
    } else {
      return Color.lerp(
        Colors.grey[300]!,
        Colors.grey[200]!,
        animationValue,
      )!;
    }
  }
}