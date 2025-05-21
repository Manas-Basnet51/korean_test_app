part of 'snackbar_cubit.dart';

enum SnackBarType {
  info,
  success,
  error,
  warning,
  progress,
}

// SnackBar State
abstract class SnackBarState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SnackBarInitial extends SnackBarState {}

class SnackBarShow extends SnackBarState {
  final String message;
  final SnackBarType type;
  final Duration duration;
  final VoidCallback? action;
  final String? actionLabel;
  final String? id;

  SnackBarShow({
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 4),
    this.action,
    this.actionLabel,
    this.id,
  });

  @override
  List<Object?> get props => [message, type, duration, actionLabel, id];
}

class SnackBarDismiss extends SnackBarState {}