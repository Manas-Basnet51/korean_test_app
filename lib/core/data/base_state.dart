import 'package:equatable/equatable.dart';
import 'package:korean_language_app/core/errors/api_result.dart';

abstract class BaseState extends Equatable {
  final bool isLoading;
  final String? error;
  final FailureType? errorType;

  const BaseState({
    this.isLoading = false,
    this.error,
    this.errorType,
  });

  bool get hasError => error != null;

  @override
  List<Object?> get props => [isLoading, error, errorType];

  BaseState copyWithBaseState({
    bool? isLoading,
    String? error,
    FailureType? errorType,
  });

  BaseState copyWithError(String message, [FailureType? type]) {
    return copyWithBaseState(
      error: message,
      errorType: type,
      isLoading: false,
    );
  }

  BaseState clearError() {
    return copyWithBaseState(
      error: null,
      errorType: null,
    );
  }
}