import 'package:korean_language_app/core/errors/api_result.dart';

extension ApiResultX<T> on ApiResult<T> {
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(String message, FailureType type) onFailure,
  }) {
    return switch (this) {
      Success(data: final data) => onSuccess(data),
      Failure(message: final msg, type: final type) => onFailure(msg, type),
    };
  }
}