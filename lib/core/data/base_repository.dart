import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/core/network/network_info.dart';

abstract class BaseRepository {
  final NetworkInfo networkInfo;

  BaseRepository(this.networkInfo);

  Future<ApiResult<T>> handleRepositoryCall<T>(
    Future<ApiResult<T>> Function() remoteCall, {
    Future<ApiResult<T>> Function()? cacheCall,
    Future<void> Function(T data)? cacheData,
  }) async {
    if (!await networkInfo.isConnected) {
      if (cacheCall != null) {
        return cacheCall();
      }
      return ApiResult.failure(
        'No internet connection',
        FailureType.network,
      );
    }

    final result = await remoteCall();
    
    if (result.isSuccess && cacheData != null) {
      try {
        await cacheData(result.data as T);
      } catch (e) {
        // Log cache error but don't affect the result
      }
    }

    return result;
  }
}