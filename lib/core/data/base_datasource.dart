import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:korean_language_app/core/errors/api_result.dart';

abstract class BaseDataSource {
  Future<ApiResult<T>> handleDataSourceCall<T>(T Function() call) async {
    try {
      final result = call();
      return ApiResult.success(result);
    } on FirebaseException catch (e) {
      return _handleFirebaseError(e);
    } on SocketException catch (e) {
      return ApiResult.failure(
        'Network error: ${e.message}',
        FailureType.network,
      );
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<T>> handleAsyncDataSourceCall<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      return ApiResult.success(result);
    } on FirebaseException catch (e) {
      return _handleFirebaseError(e);
    } on SocketException catch (e) {
      return ApiResult.failure(
        'Network error: ${e.message}',
        FailureType.network,
      );
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  ApiResult<T> _handleFirebaseError<T>(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return ApiResult.failure(
          'Permission denied: ${e.message}',
          FailureType.permission,
        );
      case 'not-found':
        return ApiResult.failure(
          'Resource not found: ${e.message}',
          FailureType.notFound,
        );
      case 'unauthenticated':
      case 'unauthorized':
        return ApiResult.failure(
          'Authentication required: ${e.message}',
          FailureType.auth,
        );
      case 'unavailable':
        return ApiResult.failure(
          'Service unavailable: ${e.message}',
          FailureType.server,
        );
      default:
        return ApiResult.failure(
          'Server error: ${e.message}',
          FailureType.server,
        );
    }
  }
}