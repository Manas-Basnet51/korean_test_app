import 'dart:async';
import 'dart:developer' as dev;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/data/base_state.dart';
import 'package:korean_language_app/core/enums/book_level.dart';
import 'package:korean_language_app/core/enums/test_category.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/features/admin/data/service/admin_permission.dart';
import 'package:korean_language_app/features/auth/domain/entities/user.dart';
import 'package:korean_language_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:korean_language_app/features/tests/data/models/test_item.dart';
import 'package:korean_language_app/features/tests/domain/repositories/tests_repository.dart';

part 'tests_state.dart';

class TestsCubit extends Cubit<TestsState> {
  final TestsRepository repository;
  final AuthCubit authCubit;
  final AdminPermissionService adminService;
  
  int _currentPage = 0;
  static const int _pageSize = 5;
  bool _isConnected = true;
  
  Timer? _searchDebounceTimer;
  static const Duration _searchDebounceDelay = Duration(milliseconds: 500);
  String _lastSearchQuery = '';
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final Stopwatch _operationStopwatch = Stopwatch();
  
  TestsCubit({
    required this.repository,
    required this.authCubit,
    required this.adminService,
  }) : super(const TestsInitial()) {
    _initializeConnectivityListener();
  }

  void _initializeConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final wasConnected = _isConnected;
      _isConnected = result != ConnectivityResult.none;
      
      if (!wasConnected && _isConnected && (state.tests.isEmpty || state.hasError)) {
        dev.log('Connection restored, reloading tests...');
        loadInitialTests();
      }
    });
  }
  
  Future<void> loadInitialTests() async {
    if (state.currentOperation.isInProgress) {
      dev.log('Load operation already in progress, skipping...');
      return;
    }
    
    _operationStopwatch.reset();
    _operationStopwatch.start();
    
    try {
      emit(state.copyWith(
        isLoading: true,
        error: null,
        errorType: null,
        currentOperation: const TestsOperation(
          type: TestsOperationType.loadTests,
          status: TestsOperationStatus.inProgress,
        ),
      ));
      
      final result = await repository.getTests(page: 0, pageSize: _pageSize);
      
      await result.fold(
        onSuccess: (tests) async {
          final hasMoreResult = await repository.hasMoreTests(tests.length);

          _currentPage = tests.length ~/ _pageSize;
          final uniqueTests = _removeDuplicates(tests);
          
          _operationStopwatch.stop();
          dev.log('loadInitialTests completed in ${_operationStopwatch.elapsedMilliseconds}ms with ${uniqueTests.length} tests');
          
          emit(TestsState(
            tests: uniqueTests,
            hasMore: hasMoreResult.fold(
              onSuccess: (hasMore) => hasMore,
              onFailure: (_, __) => false,
            ),
            currentOperation: const TestsOperation(
              type: TestsOperationType.loadTests,
              status: TestsOperationStatus.completed,
            ),
          ));
          
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          _operationStopwatch.stop();
          dev.log('loadInitialTests failed after ${_operationStopwatch.elapsedMilliseconds}ms: $message');
          
          emit(state.copyWithBaseState(
            error: message,
            errorType: type,
            isLoading: false,
          ).copyWithOperation(const TestsOperation(
            type: TestsOperationType.loadTests,
            status: TestsOperationStatus.failed,
          )));
          _clearOperationAfterDelay();
        },
      );
    } catch (e) {
      _operationStopwatch.stop();
      dev.log('Error loading initial tests after ${_operationStopwatch.elapsedMilliseconds}ms: $e');
      _handleError('Failed to load tests: $e', TestsOperationType.loadTests);
    }
  }

  Future<void> loadTestsByCategory(TestCategory category) async {
    if (state.currentOperation.isInProgress) {
      dev.log('Load operation already in progress, skipping...');
      return;
    }
    
    _operationStopwatch.reset();
    _operationStopwatch.start();
    
    try {
      emit(state.copyWith(
        isLoading: true,
        error: null,
        errorType: null,
        currentOperation: const TestsOperation(
          type: TestsOperationType.loadTests,
          status: TestsOperationStatus.inProgress,
        ),
      ));
      
      final result = await repository.getTestsByCategory(category, page: 0, pageSize: _pageSize);
      
      await result.fold(
        onSuccess: (tests) async {
          final uniqueTests = _removeDuplicates(tests);
          
          _operationStopwatch.stop();
          dev.log('loadTestsByCategory completed in ${_operationStopwatch.elapsedMilliseconds}ms with ${uniqueTests.length} tests');
          
          emit(TestsState(
            tests: uniqueTests,
            hasMore: false, // Category filtering doesn't support pagination yet
            currentOperation: const TestsOperation(
              type: TestsOperationType.loadTests,
              status: TestsOperationStatus.completed,
            ),
          ));
          
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          _operationStopwatch.stop();
          dev.log('loadTestsByCategory failed after ${_operationStopwatch.elapsedMilliseconds}ms: $message');
          
          emit(state.copyWithBaseState(
            error: message,
            errorType: type,
            isLoading: false,
          ).copyWithOperation(const TestsOperation(
            type: TestsOperationType.loadTests,
            status: TestsOperationStatus.failed,
          )));
          _clearOperationAfterDelay();
        },
      );
    } catch (e) {
      _operationStopwatch.stop();
      dev.log('Error loading tests by category after ${_operationStopwatch.elapsedMilliseconds}ms: $e');
      _handleError('Failed to load tests: $e', TestsOperationType.loadTests);
    }
  }
  
  Future<void> loadMoreTests() async {    
    if (!state.hasMore || !_isConnected || state.currentOperation.isInProgress) {
      dev.log('loadMoreTests skipped - hasMore: ${state.hasMore}, connected: $_isConnected, inProgress: ${state.currentOperation.isInProgress}');
      return;
    }
    
    _operationStopwatch.reset();
    _operationStopwatch.start();
    
    try {
      emit(state.copyWith(
        currentOperation: const TestsOperation(
          type: TestsOperationType.loadMoreTests,
          status: TestsOperationStatus.inProgress,
        ),
      ));
      
      final result = await repository.getTests(
        page: _currentPage + 1,
        pageSize: _pageSize
      );
      
      await result.fold(
        onSuccess: (moreTests) async {
          final existingIds = state.tests.map((test) => test.id).toSet();
          final uniqueNewTests = moreTests.where((test) => !existingIds.contains(test.id)).toList();
          
          if (uniqueNewTests.isNotEmpty) {
            final allTests = [...state.tests, ...uniqueNewTests];
            final hasMoreResult = await repository.hasMoreTests(allTests.length);
            
            _currentPage = allTests.length ~/ _pageSize;
            
            _operationStopwatch.stop();
            dev.log('loadMoreTests completed in ${_operationStopwatch.elapsedMilliseconds}ms with ${uniqueNewTests.length} new tests');
            
            emit(state.copyWith(
              tests: allTests,
              hasMore: hasMoreResult.fold(
                onSuccess: (hasMore) => hasMore,
                onFailure: (_, __) => false,
              ),
              currentOperation: const TestsOperation(
                type: TestsOperationType.loadMoreTests,
                status: TestsOperationStatus.completed,
              ),
            ));
          } else {
            _operationStopwatch.stop();
            dev.log('loadMoreTests completed in ${_operationStopwatch.elapsedMilliseconds}ms with no new tests');
            
            emit(state.copyWith(
              hasMore: false,
              currentOperation: const TestsOperation(
                type: TestsOperationType.loadMoreTests,
                status: TestsOperationStatus.completed,
              ),
            ));
          }
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          _operationStopwatch.stop();
          dev.log('loadMoreTests failed after ${_operationStopwatch.elapsedMilliseconds}ms: $message');
          
          emit(state.copyWithBaseState(
            error: message, 
            errorType: type
          ).copyWithOperation(const TestsOperation(
            type: TestsOperationType.loadMoreTests,
            status: TestsOperationStatus.failed,
          )));
          _clearOperationAfterDelay();
        },
      );
    } catch (e) {
      _operationStopwatch.stop();
      dev.log('Error loading more tests after ${_operationStopwatch.elapsedMilliseconds}ms: $e');
      _handleError('Failed to load more tests: $e', TestsOperationType.loadMoreTests);
    }
  }
  
  Future<void> hardRefresh() async {
    if (state.currentOperation.isInProgress) {
      dev.log('Refresh operation already in progress, skipping...');
      return;
    }
    
    _operationStopwatch.reset();
    _operationStopwatch.start();
    
    try {
      emit(state.copyWith(
        isLoading: true,
        error: null,
        errorType: null,
        currentOperation: const TestsOperation(
          type: TestsOperationType.refreshTests,
          status: TestsOperationStatus.inProgress,
        ),
      ));
      
      _currentPage = 0;
      final result = await repository.hardRefreshTests(pageSize: _pageSize);
      
      await result.fold(
        onSuccess: (tests) async {
          final uniqueTests = _removeDuplicates(tests);
          final hasMoreResult = await repository.hasMoreTests(uniqueTests.length);
          
          _currentPage = uniqueTests.length ~/ _pageSize;
          
          _operationStopwatch.stop();
          dev.log('hardRefresh completed in ${_operationStopwatch.elapsedMilliseconds}ms with ${uniqueTests.length} tests');
          
          emit(TestsState(
            tests: uniqueTests,
            hasMore: hasMoreResult.fold(
              onSuccess: (hasMore) => hasMore,
              onFailure: (_, __) => false,
            ),
            currentOperation: const TestsOperation(
              type: TestsOperationType.refreshTests,
              status: TestsOperationStatus.completed,
            ),
          ));
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          _operationStopwatch.stop();
          dev.log('hardRefresh failed after ${_operationStopwatch.elapsedMilliseconds}ms: $message');
          
          emit(state.copyWithBaseState(
            error: message,
            errorType: type,
            isLoading: false,
          ).copyWithOperation(const TestsOperation(
            type: TestsOperationType.refreshTests,
            status: TestsOperationStatus.failed,
          )));
          _clearOperationAfterDelay();
        },
      );
    } catch (e) {
      _operationStopwatch.stop();
      dev.log('Error refreshing tests after ${_operationStopwatch.elapsedMilliseconds}ms: $e');
      _handleError('Failed to refresh tests: $e', TestsOperationType.refreshTests);
    }
  }
  
  void searchTests(String query) {
    _searchDebounceTimer?.cancel();
    
    final trimmedQuery = query.trim();
    
    if (trimmedQuery.length < 2) {
      dev.log('Search query too short, restoring initial tests');
      _lastSearchQuery = '';
      loadInitialTests();
      return;
    }
    
    if (trimmedQuery == _lastSearchQuery) {
      dev.log('Duplicate search query, skipping');
      return;
    }
    
    _searchDebounceTimer = Timer(_searchDebounceDelay, () {
      _performSearch(trimmedQuery);
    });
  }
  
  Future<void> _performSearch(String query) async {
    if (state.currentOperation.isInProgress) {
      dev.log('Search operation already in progress, skipping...');
      return;
    }
    
    _operationStopwatch.reset();
    _operationStopwatch.start();
    _lastSearchQuery = query;
    
    try {
      emit(state.copyWith(
        isLoading: true,
        currentOperation: const TestsOperation(
          type: TestsOperationType.searchTests,
          status: TestsOperationStatus.inProgress,
        ),
      ));
      
      final result = await repository.searchTests(query);
      
      result.fold(
        onSuccess: (searchResults) {
          final uniqueSearchResults = _removeDuplicates(searchResults);
          
          _operationStopwatch.stop();
          dev.log('Search completed in ${_operationStopwatch.elapsedMilliseconds}ms with ${uniqueSearchResults.length} results for query: "$query"');
          
          emit(state.copyWith(
            tests: uniqueSearchResults,
            hasMore: false,
            isLoading: false,
            error: null,
            errorType: null,
            currentOperation: const TestsOperation(
              type: TestsOperationType.searchTests,
              status: TestsOperationStatus.completed,
            ),
          ));
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          _operationStopwatch.stop();
          dev.log('Search failed after ${_operationStopwatch.elapsedMilliseconds}ms: $message');
          
          emit(state.copyWithBaseState(
            error: message,
            errorType: type,
            isLoading: false,
          ).copyWithOperation(const TestsOperation(
            type: TestsOperationType.searchTests,
            status: TestsOperationStatus.failed,
          )));
          _clearOperationAfterDelay();
        },
      );
    } catch (e) {
      _operationStopwatch.stop();
      dev.log('Error searching tests after ${_operationStopwatch.elapsedMilliseconds}ms: $e');
      _handleError('Failed to search tests: $e', TestsOperationType.searchTests);
    }
  }

  Future<void> loadTestById(String testId) async {
    if (state.currentOperation.isInProgress) {
      dev.log('Load test operation already in progress, skipping...');
      return;
    }

    try {
      emit(state.copyWith(
        currentOperation: TestsOperation(
          type: TestsOperationType.loadTestById,
          status: TestsOperationStatus.inProgress,
          testId: testId,
        ),
      ));

      final result = await repository.getTestById(testId);

      result.fold(
        onSuccess: (test) {
          emit(state.copyWith(
            selectedTest: test,
            currentOperation: TestsOperation(
              type: TestsOperationType.loadTestById,
              status: TestsOperationStatus.completed,
              testId: testId,
            ),
          ));
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          emit(state.copyWithBaseState(
            error: message,
            errorType: type,
          ).copyWithOperation(TestsOperation(
            type: TestsOperationType.loadTestById,
            status: TestsOperationStatus.failed,
            testId: testId,
            message: message,
          )));
          _clearOperationAfterDelay();
        },
      );
    } catch (e) {
      _handleError('Failed to load test: $e', TestsOperationType.loadTestById, testId);
    }
  }
  
  // State management methods
  void addTestToState(TestItem test) {
    final updatedTests = [test, ...state.tests];
    final uniqueTests = _removeDuplicates(updatedTests);
    
    dev.log('Added test to state: ${test.title}');
    emit(state.copyWith(tests: uniqueTests));
  }
  
  void updateTestInState(TestItem updatedTest) {
    final testIndex = state.tests.indexWhere((t) => t.id == updatedTest.id);
    
    if (testIndex != -1) {
      final updatedTests = List<TestItem>.from(state.tests);
      updatedTests[testIndex] = updatedTest;
      
      dev.log('Updated test in state: ${updatedTest.title}');
      emit(state.copyWith(tests: updatedTests));
    } else {
      dev.log('Test not found in state for update: ${updatedTest.id}');
    }
  }

  void removeTestFromState(String testId) {
    final updatedTests = state.tests.where((t) => t.id != testId).toList();
    
    dev.log('Removed test from state: $testId');
    emit(state.copyWith(tests: updatedTests));
  }
  
  // Permission checking methods
  Future<bool> canUserEditTest(String testId) async {
    try {
      final UserEntity? user = _getCurrentUser();
      if (user == null) {
        dev.log('No authenticated user for edit permission check');
        return false;
      }
      
      if (await adminService.isUserAdmin(user.uid)) {
        dev.log('User is admin, granting edit permission for test: $testId');
        return true;
      }
      
      final test = state.tests.firstWhere(
        (t) => t.id == testId,
        orElse: () => const TestItem(
          id: '', title: '', description: '', questions: [],
          level: BookLevel.beginner, category: TestCategory.practice,
        )
      );
      
      final canEdit = test.id.isNotEmpty && test.creatorUid == user.uid;
      dev.log('Edit permission for test $testId: $canEdit (user: ${user.uid}, creator: ${test.creatorUid})');
      
      return canEdit;
    } catch (e) {
      dev.log('Error checking edit permission: $e');
      return false;
    }
  }
  
  Future<bool> canUserDeleteTest(String testId) async {
    return canUserEditTest(testId);
  }
  
  // Helper methods
  UserEntity? _getCurrentUser() {
    final authState = authCubit.state;
    if (authState is Authenticated) {
      return authState.user;
    }
    return null;
  }
  
  List<TestItem> _removeDuplicates(List<TestItem> tests) {
    final uniqueIds = <String>{};
    final uniqueTests = <TestItem>[];
    
    for (final test in tests) {
      if (uniqueIds.add(test.id)) {
        uniqueTests.add(test);
      }
    }
    
    return uniqueTests;
  }

  void _handleError(String message, TestsOperationType operationType, [String? testId]) {
    emit(state.copyWithBaseState(
      error: message,
      isLoading: false,
    ).copyWithOperation(TestsOperation(
      type: operationType,
      status: TestsOperationStatus.failed,
      message: message,
      testId: testId,
    )));
    
    _clearOperationAfterDelay();
  }

  void _clearOperationAfterDelay() {
    Timer(const Duration(seconds: 3), () {
      if (state.currentOperation.status != TestsOperationStatus.none) {
        emit(state.copyWithOperation(
          const TestsOperation(status: TestsOperationStatus.none)
        ));
      }
    });
  }

  @override
  Future<void> close() {
    dev.log('Closing TestsCubit...');
    _searchDebounceTimer?.cancel();
    _connectivitySubscription?.cancel();
    return super.close();
  }
}