import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:korean_language_app/core/enums/test_category.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/core/presentation/connectivity/bloc/connectivity_cubit.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';
import 'package:korean_language_app/core/presentation/snackbar/bloc/snackbar_cubit.dart';
import 'package:korean_language_app/core/presentation/widgets/errors/error_widget.dart';
import 'package:korean_language_app/core/routes/app_router.dart';
import 'package:korean_language_app/features/tests/data/models/test_item.dart';
import 'package:korean_language_app/features/tests/presentation/bloc/tests_cubit.dart';
import 'package:korean_language_app/features/tests/presentation/widgets/test_card.dart';
import 'package:korean_language_app/features/tests/presentation/widgets/test_grid_skeleton.dart';

class TestsPage extends StatefulWidget {
  const TestsPage({super.key});

  @override
  State<TestsPage> createState() => _TestsPageState();
}

class _TestsPageState extends State<TestsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();
  bool _isRefreshing = false;
  final Map<String, bool> _editPermissionCache = {};
  bool _isInitialized = false;
  
  TestsCubit get _testsCubit => context.read<TestsCubit>();
  LanguagePreferenceCubit get _languageCubit => context.read<LanguagePreferenceCubit>();
  SnackBarCubit get _snackBarCubit => context.read<SnackBarCubit>();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: TestCategory.values.length - 1,
      vsync: this,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testsCubit.loadInitialTests();
      context.read<ConnectivityCubit>().checkConnectivity();
      setState(() {
        _isInitialized = true;
      });
    });
    
    _scrollController.addListener(_onScroll);
    _tabController.addListener(_onTabChanged);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_isNearBottom && !_isRefreshing) {
      final state = _testsCubit.state;
      
      if (state.hasMore && !state.currentOperation.isInProgress) {
        _testsCubit.loadMoreTests();
      }
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    
    final category = _getCategoryForIndex(_tabController.index);
    if (category == TestCategory.all) {
      _testsCubit.loadInitialTests();
    } else {
      _testsCubit.loadTestsByCategory(category);
    }
    _editPermissionCache.clear();
  }
  
  bool get _isNearBottom {
    if (!_scrollController.hasClients) return false;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
  
  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    
    try {
      await _testsCubit.hardRefresh();
      _editPermissionCache.clear();
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  Future<bool> _checkEditPermission(String testId) async {
    if (_editPermissionCache.containsKey(testId)) {
      return _editPermissionCache[testId]!;
    }
    
    final hasPermission = await _testsCubit.canUserEditTest(testId);
    _editPermissionCache[testId] = hasPermission;
    return hasPermission;
  }

  TestCategory _getCategoryForIndex(int index) {
    final categories = TestCategory.values.where((c) => c != TestCategory.all).toList();
    if (index >= 0 && index < categories.length) {
      return categories[index];
    }
    return TestCategory.practice;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: _buildAppBar(theme, colorScheme),
      body: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, connectivityState) {
          final bool isOffline = connectivityState is ConnectivityDisconnected;
          
          return Column(
            children: [
              if (isOffline)
                ErrorView(
                  message: '',
                  errorType: FailureType.network,
                  onRetry: () {
                    context.read<ConnectivityCubit>().checkConnectivity();
                  },
                  isCompact: true,
                ),
              
              _buildCategoryTabs(theme),
              Expanded(
                child: _buildTestsContent(isOffline),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.testUpload),
        tooltip: _languageCubit.getLocalizedText(
          korean: '시험 만들기',
          english: 'Create Test',
        ),
        child: const Icon(Icons.add),
      )
    );
  }
  
  AppBar _buildAppBar(ThemeData theme, ColorScheme colorScheme) {
    return AppBar(
      title: Text(
        _languageCubit.getLocalizedText(
          korean: '시험',
          english: 'Tests',
        ),
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      elevation: 0,
      backgroundColor: colorScheme.surface,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearchDelegate(),
        ),
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () {
            context.push(Routes.testResults);
          },
          tooltip: _languageCubit.getLocalizedText(
            korean: '내 결과',
            english: 'My Results',
          ),
        ),
      ],
    );
  }
  Widget _buildCategoryTabs(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        labelStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: theme.textTheme.titleSmall,
        indicatorColor: theme.colorScheme.primary,
        tabs: TestCategory.values
            .where((category) => category != TestCategory.all)
            .map((category) => Tab(
                  child: Text(
                    _languageCubit.getLocalizedText(
                      korean: _getCategoryNameKorean(category),
                      english: category.name,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  String _getCategoryNameKorean(TestCategory category) {
    switch (category) {
      case TestCategory.topikI:
        return 'TOPIK I';
      case TestCategory.topikII:
        return 'TOPIK II';
      case TestCategory.practice:
        return '연습';
      case TestCategory.all:
        return '전체';
    }
  }
  
  Widget _buildTestsContent(bool isOffline) {
    return BlocConsumer<TestsCubit, TestsState>(
      listener: (context, state) {
        final operation = state.currentOperation;
        
        if (operation.status == TestsOperationStatus.failed) {
          String errorMessage = operation.message ?? 'Operation failed';
          
          switch (operation.type) {
            case TestsOperationType.loadTests:
              errorMessage = 'Failed to load tests';
              break;
            case TestsOperationType.loadMoreTests:
              errorMessage = 'Failed to load more tests';
              break;
            case TestsOperationType.searchTests:
              errorMessage = 'Failed to search tests';
              break;
            case TestsOperationType.refreshTests:
              errorMessage = 'Failed to refresh tests';
              break;
            default:
              break;
          }
          
          _snackBarCubit.showErrorLocalized(
            korean: errorMessage,
            english: errorMessage,
          );
        }
        
        if (state.hasError) {
          _snackBarCubit.showErrorLocalized(
            korean: state.error ?? '오류가 발생했습니다.',
            english: state.error ?? 'An error occurred.',
          );
        }
      },
      builder: (context, state) {
        if (isOffline && state.tests.isEmpty && state.isLoading) {
          return ErrorView(
            message: '',
            errorType: FailureType.network,
            onRetry: () {
              context.read<ConnectivityCubit>().checkConnectivity();
              if (context.read<ConnectivityCubit>().state is ConnectivityConnected) {
                _testsCubit.loadInitialTests();
              }
            },
          );
        }
        
        if (state.isLoading && state.tests.isEmpty) {
          return const TestGridSkeleton();
        }
        
        if (state.hasError && state.tests.isEmpty) {
          return ErrorView(
            message: state.error ?? '',
            errorType: state.errorType,
            onRetry: () {
              _testsCubit.loadInitialTests();
            },
          );
        }
        
        return _buildTestsList(state, isOffline);
      },
    );
  }
  
  Widget _buildTestsList(TestsState state, bool isOffline) {
    if (state.tests.isEmpty) {
      return _buildEmptyTestsView();
    }
    
    final isLoadingMore = state.currentOperation.type == TestsOperationType.loadMoreTests && 
                         state.currentOperation.isInProgress;
    
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Column(
        children: [
          if (state.hasError)
            ErrorView(
              message: state.error ?? '',
              errorType: state.errorType,
              onRetry: () {
                _testsCubit.loadInitialTests();
              },
              isCompact: true,
            ),
          
          Expanded(
            child: Stack(
              children: [
                GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: state.tests.length,
                  itemBuilder: (context, index) {
                    final test = state.tests[index];
                    return FutureBuilder<bool>(
                      future: _checkEditPermission(test.id),
                      builder: (context, snapshot) {
                        final canEdit = snapshot.data ?? false;
                        
                        return TestCard(
                          key: ValueKey(test.id),
                          test: test,
                          canEdit: canEdit,
                          onTap: () => _startTest(test),
                          onEdit: canEdit ? () => _editTest(test) : null,
                          onDelete: canEdit ? () => _deleteTest(test) : null,
                          onViewDetails: () => _viewTestDetails(test),
                        );
                      },
                    );
                  },
                ),
                if (isLoadingMore)
                  const Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyTestsView() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              Icon(
                Icons.quiz_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                _languageCubit.getLocalizedText(
                  korean: '시험이 없습니다',
                  english: 'No tests available',
                ),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _languageCubit.getLocalizedText(
                    korean: '새 시험을 만들려면 + 버튼을 누르세요',
                    english: 'Tap the + button to create a new test',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showSearchDelegate() {
    _snackBarCubit.showInfoLocalized(
      korean: '검색 기능이 곧 제공될 예정입니다',
      english: 'Search functionality coming soon',
    );
  }
  
  void _startTest(TestItem test) {
    // Check if test.id is not empty before navigation
    if (test.id.isEmpty) {
      _snackBarCubit.showErrorLocalized(
        korean: '시험 ID가 유효하지 않습니다',
        english: 'Invalid test ID',
      );
      return;
    }
    context.push(Routes.testTaking(test.id));
  }
  
  void _viewTestDetails(TestItem test) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildTestDetailsBottomSheet(test),
    );
  }

  Widget _buildTestDetailsBottomSheet(TestItem test) {
    final theme = Theme.of(context);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 16),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      test.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        _buildDetailChip(
                          icon: Icons.quiz,
                          label: '${test.questionCount} Questions',
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        _buildDetailChip(
                          icon: Icons.timer,
                          label: test.formattedTimeLimit,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        _buildDetailChip(
                          icon: Icons.school,
                          label: test.level.toString().split('.').last,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Information',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildInfoRow('Passing Score', test.formattedPassingScore),
                      _buildInfoRow('Category', test.category.name),
                      _buildInfoRow('Language', test.language),
                      if (test.createdAt != null)
                        _buildInfoRow('Created', _formatDate(test.createdAt!)),
                      
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _startTest(test);
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Test'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  void _editTest(TestItem test) async {
    // Check if test.id is not empty before checking permissions
    if (test.id.isEmpty) {
      _snackBarCubit.showErrorLocalized(
        korean: '시험 ID가 유효하지 않습니다',
        english: 'Invalid test ID',
      );
      return;
    }

    final hasPermission = await _testsCubit.canUserEditTest(test.id);
    if (!hasPermission) {
      _snackBarCubit.showErrorLocalized(
        korean: '이 시험을 편집할 권한이 없습니다',
        english: 'You do not have permission to edit this test',
      );
      return;
    }

    final result = await context.push(Routes.testEdit(test.id)); // Updated to use Routes

    if (result == true) {
      _refreshData();
    }
  }

  void _deleteTest(TestItem test) async {
    final hasPermission = await _testsCubit.canUserDeleteTest(test.id);
    if (!hasPermission) {
      _snackBarCubit.showErrorLocalized(
        korean: '이 시험을 삭제할 권한이 없습니다',
        english: 'You do not have permission to delete this test',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _languageCubit.getLocalizedText(
            korean: '시험 삭제',
            english: 'Delete Test',
          ),
        ),
        content: Text(
          _languageCubit.getLocalizedText(
            korean: '"${test.title}"을(를) 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.',
            english: 'Are you sure you want to delete "${test.title}"? This action cannot be undone.',
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              _languageCubit.getLocalizedText(
                korean: '취소',
                english: 'CANCEL',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              _languageCubit.getLocalizedText(
                korean: '삭제',
                english: 'DELETE',
              ),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      // Delete test using TestsCubit
      final success = await _testsCubit.deleteExistingTest(test.id);
      
      if (success) {
        _snackBarCubit.showSuccessLocalized(
          korean: '시험이 성공적으로 삭제되었습니다',
          english: 'Test deleted successfully',
        );
        
        // Refresh the test list
        _refreshData();
      } else {
        _snackBarCubit.showErrorLocalized(
          korean: '시험 삭제에 실패했습니다',
          english: 'Failed to delete test',
        );
      }
    }
  }
}