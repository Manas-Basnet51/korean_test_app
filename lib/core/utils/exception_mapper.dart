import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:korean_language_app/core/errors/api_result.dart';

class ExceptionMapper {

  static ApiResult<T> mapExceptionToApiResult<T>(Exception e) {
    final message = e.toString();
    
    if (message.contains('Permission denied')) {
      return ApiResult.failure(message, FailureType.permission);
    } else if (message.contains('not found') || message.contains('Resource not found')) {
      return ApiResult.failure(message, FailureType.notFound);
    } else if (message.contains('Authentication required')) {
      return ApiResult.failure(message, FailureType.auth);
    } else if (message.contains('Service unavailable') || message.contains('Server error')) {
      return ApiResult.failure(message, FailureType.server);
    } else if (message.contains('No internet connection')) {
      return ApiResult.failure(message, FailureType.network);
    } else if (message.contains('validation') || message.contains('cannot be empty')) {
      return ApiResult.failure(message, FailureType.validation);
    } else {
      return ApiResult.failure(message, FailureType.unknown);
    }
  }

  static Exception mapFirebaseException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('Permission denied: ${e.message}');
      case 'not-found':
        return Exception('Resource not found: ${e.message}');
      case 'unauthenticated':
      case 'unauthorized':
        return Exception('Authentication required: ${e.message}');
      case 'unavailable':
        return Exception('Service unavailable: ${e.message}');
      default:
        return Exception('Server error: ${e.message}');
    }
  }

}