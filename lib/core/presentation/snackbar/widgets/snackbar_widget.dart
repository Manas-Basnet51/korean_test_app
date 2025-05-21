import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/presentation/snackbar/bloc/snackbar_cubit.dart';

class SnackBarWidget extends StatelessWidget {
  final Widget child;
  
  const SnackBarWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<SnackBarCubit, SnackBarState>(
      listener: (context, state) {
        if (state is SnackBarShow) {
          _showSnackBar(context, state);
        } else if (state is SnackBarDismiss) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      },
      child: child,
    );
  }

  void _showSnackBar(BuildContext context, SnackBarShow state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Configure appearance based on type
    Color backgroundColor;
    Color textColor;
    IconData iconData;
    
    switch (state.type) {
      case SnackBarType.info:
        backgroundColor = colorScheme.primary;
        textColor = colorScheme.onPrimary;
        iconData = Icons.info_outline;
        break;
      case SnackBarType.success:
        backgroundColor = Colors.green;
        textColor = Colors.white;
        iconData = Icons.check_circle_outline;
        break;
      case SnackBarType.error:
        backgroundColor = colorScheme.error;
        textColor = colorScheme.onError;
        iconData = Icons.error_outline;
        break;
      case SnackBarType.warning:
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        iconData = Icons.warning_amber_outlined;
        break;
      case SnackBarType.progress:
        backgroundColor = colorScheme.tertiary;
        textColor = colorScheme.onTertiary;
        iconData = Icons.info_outline; // Will be replaced by progress indicator
        break;
    }
    
    // Create action if provided
    SnackBarAction? action;
    if (state.action != null && state.actionLabel != null) {
      action = SnackBarAction(
        label: state.actionLabel!,
        textColor: textColor,
        onPressed: state.action!,
      );
    }
    
    // Build the content
    Widget content;
    if (state.type == SnackBarType.progress) {
      content = Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              state.message,
              style: TextStyle(color: textColor),
            ),
          ),
        ],
      );
    } else {
      content = Row(
        children: [
          Icon(iconData, color: textColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              state.message,
              style: TextStyle(color: textColor),
            ),
          ),
        ],
      );
    }
    
    final snackBar = SnackBar(
      content: content,
      backgroundColor: backgroundColor,
      duration: state.duration,
      behavior: SnackBarBehavior.floating,
      action: action,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}