import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/data/base_state.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/core/services/auth_service.dart';
import 'package:korean_language_app/features/auth/domain/entities/user.dart';
import 'package:korean_language_app/features/test_results/data/models/test_result.dart';
import 'package:korean_language_app/features/test_results/domain/repositories/test_results_repository.dart';

part 'test_results_state.dart';

class TestResultsCubit extends Cubit<TestResultsState> {
  final TestResultsRepository repository;
  final AuthService authService;
  
  final Stopwatch _operationStopwatch = Stopwatch();
  
  TestResultsCubit({
    required this.repository,
    required this.authService,
  }) : super(const TestResultsInitial());

  Future<void> saveTestResult(TestResult testResult) async {
    if (state.currentOperation.isInProgress) {
      dev.log('Save result operation already in progress, skipping...');
      return;
    }

    _operationStopwatch.reset();
    _operationStopwatch.start();

    try {
      emit(state.copyWith(
        isLoading: true,
        error: null,
        errorType: null,
        currentOperation: const TestResultsOperation(
          type: TestResultsOperationType.saveResult,
          status: TestResultsOperationStatus.inProgress,
        ),
      ));

      final result = await repository.saveTestResult(testResult);

      result.fold(
        onSuccess: (_) {
          _operationStopwatch.stop();
          dev.log('Test result saved successfully in ${_operationStopwatch.elapsedMilliseconds}ms');
          
          emit(state.copyWith(
            isLoading: false,
            error: null,
            errorType: null,
            currentOperation: const TestResultsOperation(
              type: TestResultsOperationType.saveResult,
              status: TestResultsOperationStatus.completed,
            ),
          ));
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          _operationStopwatch.stop();
          dev.log('Save result failed after ${_operationStopwatch.elapsedMilliseconds}ms: $message');
          
          emit(state.copyWithBaseState(
            error: message,
            errorType: type,
            isLoading: false,
          ).copyWithOperation(TestResultsOperation(
            type: TestResultsOperationType.saveResult,
            status: TestResultsOperationStatus.failed,
            message: message,
          )));
          _clearOperationAfterDelay();
        },
      );
    } catch (e) {
      _operationStopwatch.stop();
      dev.log('Error saving test result after ${_operationStopwatch.elapsedMilliseconds}ms: $e');
      _handleError('Failed to save test result: $e', TestResultsOperationType.saveResult);
    }
  }

  Future<void> loadUserResults({int limit = 20}) async {
    final UserEntity? user = _getCurrentUser();
    if (user == null) {
      dev.log('No authenticated user for loading results');
      emit(state.copyWithBaseState(
        error: 'User not authenticated',
        errorType: FailureType.auth,
      ));
      return;
    }

    if (state.currentOperation.isInProgress) {
      dev.log('Load results operation already in progress, skipping...');
      return;
    }

    _operationStopwatch.reset();
    _operationStopwatch.start();

    try {
      emit(state.copyWith(
        isLoading: true,
        error: null,
        errorType: null,
        currentOperation: const TestResultsOperation(
          type: TestResultsOperationType.loadResults,
          status: TestResultsOperationStatus.inProgress,
        ),
      ));

      final result = await repository.getUserTestResults(user.uid, limit: limit);

      result.fold(
        onSuccess: (results) {
          _operationStopwatch.stop();
          dev.log('Loaded ${results.length} user results in ${_operationStopwatch.elapsedMilliseconds}ms');
          
          emit(state.copyWith(
            isLoading: false,
            error: null,
            errorType: null,
            results: results,
            currentOperation: const TestResultsOperation(
              type: TestResultsOperationType.loadResults,
              status: TestResultsOperationStatus.completed,
            ),
          ));
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          _operationStopwatch.stop();
          dev.log('Load results failed after ${_operationStopwatch.elapsedMilliseconds}ms: $message');
          
          emit(state.copyWithBaseState(
            error: message,
            errorType: type,
            isLoading: false,
          ).copyWithOperation(TestResultsOperation(
            type: TestResultsOperationType.loadResults,
            status: TestResultsOperationStatus.failed,
            message: message,
          )));
          _clearOperationAfterDelay();
        },
      );
    } catch (e) {
      _operationStopwatch.stop();
      dev.log('Error loading user results after ${_operationStopwatch.elapsedMilliseconds}ms: $e');
      _handleError('Failed to load user results: $e', TestResultsOperationType.loadResults);
    }
  }

  Future<void> loadTestResults(String testId, {int limit = 50}) async {
    if (state.currentOperation.isInProgress) {
      dev.log('Load test results operation already in progress, skipping...');
      return;
    }

    _operationStopwatch.reset();
    _operationStopwatch.start();

    try {
      emit(state.copyWith(
        isLoading: true,
        error: null,
        errorType: null,
        currentOperation: TestResultsOperation(
          type: TestResultsOperationType.loadTestResults,
          status: TestResultsOperationStatus.inProgress,
          testId: testId,
        ),
      ));

      final result = await repository.getTestResults(testId, limit: limit);

      result.fold(
        onSuccess: (results) {
          _operationStopwatch.stop();
          dev.log('Loaded ${results.length} test results for test $testId in ${_operationStopwatch.elapsedMilliseconds}ms');
          
          emit(state.copyWith(
            isLoading: false,
            error: null,
            errorType: null,
            testResults: results,
            currentOperation: TestResultsOperation(
              type: TestResultsOperationType.loadTestResults,
              status: TestResultsOperationStatus.completed,
              testId: testId,
            ),
          ));
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          _operationStopwatch.stop();
          dev.log('Load test results failed after ${_operationStopwatch.elapsedMilliseconds}ms: $message');
          
          emit(state.copyWithBaseState(
            error: message,
            errorType: type,
            isLoading: false,
          ).copyWithOperation(TestResultsOperation(
            type: TestResultsOperationType.loadTestResults,
            status: TestResultsOperationStatus.failed,
            testId: testId,
            message: message,
          )));
          _clearOperationAfterDelay();
        },
      );
    } catch (e) {
      _operationStopwatch.stop();
      dev.log('Error loading test results after ${_operationStopwatch.elapsedMilliseconds}ms: $e');
      _handleError('Failed to load test results: $e', TestResultsOperationType.loadTestResults, testId);
    }
  }

  Future<void> loadUserLatestResult(String testId) async {
    final UserEntity? user = _getCurrentUser();
    if (user == null) {
      dev.log('No authenticated user for loading latest result');
      return;
    }

    try {
      final result = await repository.getUserLatestResult(user.uid, testId);
      
      result.fold(
        onSuccess: (latestResult) {
          emit(state.copyWith(latestResult: latestResult));
        },
        onFailure: (message, type) {
          dev.log('Failed to load latest result: $message');
        },
      );
    } catch (e) {
      dev.log('Error loading latest result: $e');
    }
  }

  // High-level helper methods for UI
  Future<List<TestResult>> getUserTestResultsWithHandling() async {
    try {
      final UserEntity? user = _getCurrentUser();
      if (user == null) {
        dev.log('No authenticated user for getting test results');
        return [];
      }

      final result = await repository.getUserTestResults(user.uid);
      
      return result.fold(
        onSuccess: (results) {
          dev.log('Retrieved ${results.length} test results for user: ${user.uid}');
          return results;
        },
        onFailure: (message, type) {
          dev.log('Failed to get user test results: $message');
          return [];
        },
      );
    } catch (e) {
      dev.log('Error getting user test results: $e');
      return [];
    }
  }

  Future<List<TestResult>> getCachedUserResults() async {
    try {
      final UserEntity? user = _getCurrentUser();
      if (user == null) {
        dev.log('No authenticated user for getting cached test results');
        return [];
      }

      final result = await repository.getCachedUserResults(user.uid);
      
      return result.fold(
        onSuccess: (results) {
          dev.log('Retrieved ${results.length} cached test results for user: ${user.uid}');
          return results;
        },
        onFailure: (message, type) {
          dev.log('Failed to get cached user test results: $message');
          return [];
        },
      );
    } catch (e) {
      dev.log('Error getting cached user test results: $e');
      return [];
    }
  }

  Future<List<TestResult>> getTestResultsWithHandling() async {
    try {
      final results = await getUserTestResultsWithHandling();
      if (results.isNotEmpty) {
        return results;
      }
      
      return await getCachedUserResults();
    } catch (e) {
      dev.log('Error getting test results: $e');
      return [];
    }
  }

  Future<void> clearUserResults() async {
    final UserEntity? user = _getCurrentUser();
    if (user == null) {
      dev.log('No authenticated user for clearing results');
      return;
    }

    try {
      await repository.clearUserResults(user.uid);
      emit(state.copyWith(results: []));
    } catch (e) {
      dev.log('Error clearing user results: $e');
    }
  }

  // Helper methods
  UserEntity? _getCurrentUser() {
    return authService.getCurrentUser();
  }

  void _handleError(String message, TestResultsOperationType operationType, [String? testId]) {
    emit(state.copyWithBaseState(
      error: message,
      isLoading: false,
    ).copyWithOperation(TestResultsOperation(
      type: operationType,
      status: TestResultsOperationStatus.failed,
      message: message,
      testId: testId,
    )));
    
    _clearOperationAfterDelay();
  }

  void _clearOperationAfterDelay() {
    Timer(const Duration(seconds: 3), () {
      if (state.currentOperation.status != TestResultsOperationStatus.none) {
        emit(state.copyWithOperation(
          const TestResultsOperation(status: TestResultsOperationStatus.none)
        ));
      }
    });
  }

  @override
  Future<void> close() {
    dev.log('Closing TestResultsCubit...');
    return super.close();
  }
}