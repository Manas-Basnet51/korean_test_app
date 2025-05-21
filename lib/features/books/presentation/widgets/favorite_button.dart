import 'package:flutter/material.dart';

class AnimatedFavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onPressed;
  final double size;
  final bool useGradientBackground;
  
  const AnimatedFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.size = 20,
    this.useGradientBackground = false,
  });

  @override
  State<AnimatedFavoriteButton> createState() => _AnimatedFavoriteButtonState();
}

class _AnimatedFavoriteButtonState extends State<AnimatedFavoriteButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.8), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: 1.4), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.4, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.9, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerAnimation() {
    if (_controller.status == AnimationStatus.completed) {
      _controller.reset();
    }
    _controller.forward();
    widget.onPressed();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: _triggerAnimation,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isFavorite 
                  ? Colors.red.withValues( alpha: 0.2) 
                  : Colors.black.withValues( alpha: 0.4),
              shape: BoxShape.circle,
              gradient: widget.useGradientBackground && widget.isFavorite
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.withValues( alpha: 0.7),
                        Colors.redAccent.withValues( alpha: 0.3),
                      ],
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: widget.isFavorite 
                      ? Colors.red.withValues( alpha: 0.3)
                      : Colors.black.withValues( alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: widget.isFavorite ? Colors.redAccent : Colors.white,
                size: widget.size * _bounceAnimation.value,
              ),
            ),
          ),
        );
      }
    );
  }
}