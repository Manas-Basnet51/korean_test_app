import 'package:flutter/material.dart';

// ErrorBoundary implementation similar to React's ErrorBoundary for component-level error handling
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context, Object error)? fallbackBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallbackBuilder,
  });

  @override
  ErrorBoundaryState createState() => ErrorBoundaryState();
}

class ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  static final _instances = <ErrorBoundaryState>{};

  @override
  void initState() {
    super.initState();
    _instances.add(this);
  }

  @override
  void dispose() {
    _instances.remove(this);
    super.dispose();
  }

  // Method to handle errors within this boundary
  void onError(Object error) {
    setState(() {
      _error = error;
    });
  }

  // Reset the error state
  void reset() {
    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.fallbackBuilder != null) {
      return widget.fallbackBuilder!(context, _error!);
    }
    
    return _ErrorCatcher(
      onError: onError,
      child: widget.child,
    );
  }
}

// Internal widget to catch errors
class _ErrorCatcher extends StatefulWidget {
  final Widget child;
  final Function(Object error) onError;

  const _ErrorCatcher({
    required this.child,
    required this.onError,
  });

  @override
  _ErrorCatcherState createState() => _ErrorCatcherState();
}

class _ErrorCatcherState extends State<_ErrorCatcher> {
  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      widget.onError(details.exception);
    };
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}