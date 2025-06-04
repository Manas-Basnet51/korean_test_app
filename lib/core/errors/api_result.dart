sealed class ApiResult<T> {
  const ApiResult();
  
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
  
  T? get data => this is Success<T> ? (this as Success<T>).data : null;
  String? get error => this is Failure<T> ? (this as Failure<T>).message : null;

  static ApiResult<T> success<T>(T data) => Success(data);
  static ApiResult<T> failure<T>(String message, [FailureType? type]) => 
    Failure(message, type ?? FailureType.unknown);
}

class Success<T> extends ApiResult<T> {
  @override
  final T data;
  const Success(this.data);
}

class Failure<T> extends ApiResult<T> {
  final String message;
  final FailureType type;
  const Failure(this.message, this.type);
}

enum FailureType {
  network,
  server,
  auth,
  cache,
  validation,
  notFound,
  permission,
  unknown
}

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