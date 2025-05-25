import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final FailureType? errorType;
  final VoidCallback onRetry;
  final bool isCompact;

  const ErrorView({
    super.key,
    required this.message,
    this.errorType,
    required this.onRetry,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageCubit = context.read<LanguagePreferenceCubit>();
    
    if (isCompact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: _getErrorColor(context, errorType),
        child: Row(
          children: [
            Icon(_getErrorIcon(errorType), color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getErrorBannerMessage(errorType, languageCubit),
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                languageCubit.getLocalizedText(
                  korean: '다시 시도',
                  english: 'Retry',
                  hardWords: [],
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getErrorIcon(errorType),
            size: 48,
            color: _getErrorColor(context, errorType),
          ),
          const SizedBox(height: 16),
          Text(
            _getErrorTitle(errorType, languageCubit),
            style: theme.textTheme.titleLarge?.copyWith(
              color: _getErrorColor(context, errorType),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _getErrorMessage(message, errorType, languageCubit),
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(
              languageCubit.getLocalizedText(
                korean: '다시 시도',
                english: 'Try Again',
                hardWords: [],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Utility methods for consistent error handling
  IconData _getErrorIcon(FailureType? type) {
    switch (type) {
      case FailureType.network:
        return Icons.wifi_off;
      case FailureType.server:
        return Icons.cloud_off;
      case FailureType.auth:
        return Icons.lock;
      case FailureType.permission:
        return Icons.no_accounts;
      case FailureType.cache:
        return Icons.storage;
      case FailureType.validation:
        return Icons.error_outline;
      case FailureType.notFound:
        return Icons.find_in_page;
      default:
        return Icons.error_outline;
    }
  }

  Color _getErrorColor(BuildContext context, FailureType? type) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case FailureType.network:
        return Colors.orange;
      case FailureType.server:
        return Colors.red;
      case FailureType.auth:
        return colorScheme.primary;
      case FailureType.permission:
        return Colors.purple;
      case FailureType.cache:
        return Colors.amber;
      case FailureType.validation:
        return Colors.deepOrange;
      case FailureType.notFound:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getErrorTitle(FailureType? type, LanguagePreferenceCubit languageCubit) {
    return languageCubit.getLocalizedText(
      korean: _getErrorTitleKorean(type),
      english: _getErrorTitleEnglish(type),
      hardWords: [],
    );
  }

  String _getErrorTitleKorean(FailureType? type) {
    switch (type) {
      case FailureType.network:
        return '인터넷 연결 없음';
      case FailureType.server:
        return '서버 오류';
      case FailureType.auth:
        return '인증 필요';
      case FailureType.permission:
        return '권한 없음';
      case FailureType.cache:
        return '캐시 오류';
      case FailureType.validation:
        return '유효성 검사 오류';
      case FailureType.notFound:
        return '찾을 수 없음';
      default:
        return '오류가 발생했습니다';
    }
  }

  String _getErrorTitleEnglish(FailureType? type) {
    switch (type) {
      case FailureType.network:
        return 'No Internet Connection';
      case FailureType.server:
        return 'Server Error';
      case FailureType.auth:
        return 'Authentication Required';
      case FailureType.permission:
        return 'Permission Denied';
      case FailureType.cache:
        return 'Cache Error';
      case FailureType.validation:
        return 'Validation Error';
      case FailureType.notFound:
        return 'Not Found';
      default:
        return 'Something Went Wrong';
    }
  }

  String _getErrorMessage(String message, FailureType? type, LanguagePreferenceCubit languageCubit) {
    // If message is already localized or error-specific, return it
    if (message.contains(languageCubit.getLocalizedText(korean: '오류', english: 'Error', hardWords: []))) {
      return message;
    }
    
    switch (type) {
      case FailureType.network:
        return languageCubit.getLocalizedText(
          korean: '인터넷 연결을 확인하고 다시 시도해 주세요.',
          english: 'Please check your internet connection and try again.',
          hardWords: [],
        );
      case FailureType.server:
        return languageCubit.getLocalizedText(
          korean: '서버와 통신하는 중 오류가 발생했습니다. 나중에 다시 시도해 주세요.',
          english: 'There was an error communicating with the server. Please try again later.',
          hardWords: [],
        );
      case FailureType.auth:
        return languageCubit.getLocalizedText(
          korean: '이 기능을 사용하려면 로그인이 필요합니다.',
          english: 'You need to be logged in to use this feature.',
          hardWords: [],
        );
      case FailureType.permission:
        return languageCubit.getLocalizedText(
          korean: '이 작업을 수행할 권한이 없습니다.',
          english: 'You don\'t have permission to perform this action.',
          hardWords: [],
        );
      // Add more error types as needed
      default:
        return message;
    }
  }

  String _getErrorBannerMessage(FailureType? type, LanguagePreferenceCubit languageCubit) {
    switch (type) {
      case FailureType.network:
        return languageCubit.getLocalizedText(
          korean: '인터넷 연결 문제로 캐시된 데이터를 표시합니다.',
          english: 'Showing cached data due to network issues.',
          hardWords: ['캐시된 데이터'],
        );
      case FailureType.server:
        return languageCubit.getLocalizedText(
          korean: '서버 문제로 캐시된 데이터를 표시합니다.',
          english: 'Showing cached data due to server issues.',
          hardWords: ['캐시된 데이터'],
        );
      case FailureType.cache:
        return languageCubit.getLocalizedText(
          korean: '캐시 오류. 일부 데이터가 최신 상태가 아닐 수 있습니다.',
          english: 'Cache error. Some data may not be up to date.',
          hardWords: [],
        );
      default:
        return languageCubit.getLocalizedText(
          korean: '데이터 로드 중 오류가 발생했습니다. 캐시된 데이터를 표시합니다.',
          english: 'Error loading data. Showing cached data.',
          hardWords: ['캐시된 데이터'],
        );
    }
  }
}