import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:korean_language_app/core/enums/book_level.dart';
import 'package:korean_language_app/core/enums/test_category.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';
import 'package:korean_language_app/core/presentation/snackbar/bloc/snackbar_cubit.dart';
import 'package:korean_language_app/features/test_upload/presentation/bloc/test_upload_cubit.dart';
import 'package:korean_language_app/core/models/test_item.dart';
import 'package:korean_language_app/core/models/test_question.dart';
import 'package:korean_language_app/features/test_upload/presentation/widgets/question_editor_page.dart';
import 'package:korean_language_app/features/tests/presentation/bloc/tests_cubit.dart';

class TestEditPage extends StatefulWidget {
  final String testId;

  const TestEditPage({super.key, required this.testId});

  @override
  State<TestEditPage> createState() => _TestEditPageState();
}

class _TestEditPageState extends State<TestEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeLimitController = TextEditingController();
  final _passingScoreController = TextEditingController();
  
  BookLevel _selectedLevel = BookLevel.beginner;
  TestCategory _selectedCategory = TestCategory.practice;
  String _selectedLanguage = 'Korean';
  IconData _selectedIcon = Icons.quiz;
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isPublished = true;
  
  List<TestQuestion> _questions = [];
  bool _isLoading = true;
  bool _isUpdating = false;
  TestItem? _originalTest;
  
  final ImagePicker _imagePicker = ImagePicker();
  
  TestsCubit get _testsCubit => context.read<TestsCubit>();
  TestUploadCubit get _testUploadCubit => context.read<TestUploadCubit>();
  LanguagePreferenceCubit get _languageCubit => context.read<LanguagePreferenceCubit>();
  SnackBarCubit get _snackBarCubit => context.read<SnackBarCubit>();

  @override
  void initState() {
    super.initState();
    _loadTest();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeLimitController.dispose();
    _passingScoreController.dispose();
    super.dispose();
  }

  Future<void> _loadTest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _testsCubit.loadTestById(widget.testId);
      
      final testsState = _testsCubit.state;
      if (testsState.selectedTest != null) {
        _originalTest = testsState.selectedTest!;
        _populateFields(_originalTest!);
      } else {
        _snackBarCubit.showErrorLocalized(
          korean: '시험을 찾을 수 없습니다',
          english: 'Test not found',
        );
        context.pop();
      }
    } catch (e) {
      _snackBarCubit.showErrorLocalized(
        korean: '시험을 불러오는 중 오류가 발생했습니다',
        english: 'Error loading test',
      );
      context.pop();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFields(TestItem test) {
    _titleController.text = test.title;
    _descriptionController.text = test.description;
    _timeLimitController.text = test.timeLimit > 0 ? test.timeLimit.toString() : '';
    _passingScoreController.text = test.passingScore.toString();
    
    setState(() {
      _selectedLevel = test.level;
      _selectedCategory = test.category;
      _selectedLanguage = test.language;
      _selectedIcon = test.icon;
      _currentImageUrl = test.imageUrl;
      _isPublished = test.isPublished;
      _questions = List.from(test.questions);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(
            _languageCubit.getLocalizedText(
              korean: '시험 편집',
              english: 'Edit Test',
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                _languageCubit.getLocalizedText(
                  korean: '시험을 불러오는 중...',
                  english: 'Loading test...',
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _languageCubit.getLocalizedText(
                korean: '시험 편집',
                english: 'Edit Test',
              ),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (_originalTest != null)
              Text(
                _originalTest!.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isUpdating ? null : _updateTest,
              style: TextButton.styleFrom(
                backgroundColor: _isUpdating ? Colors.grey.shade300 : colorScheme.primary,
                foregroundColor: _isUpdating ? Colors.grey.shade600 : colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isUpdating
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
                      ),
                    )
                  : Text(
                      _languageCubit.getLocalizedText(
                        korean: '저장',
                        english: 'Save',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
      body: BlocListener<TestUploadCubit, TestUploadState>(
        listener: (context, state) {
          if (state.currentOperation.status == TestUploadOperationStatus.completed &&
              state.currentOperation.type == TestUploadOperationType.updateTest) {
            _snackBarCubit.showSuccessLocalized(
              korean: '시험이 성공적으로 수정되었습니다',
              english: 'Test updated successfully',
            );
            context.pop(true);
          } else if (state.currentOperation.status == TestUploadOperationStatus.failed) {
            _snackBarCubit.showErrorLocalized(
              korean: state.error ?? '시험 수정에 실패했습니다',
              english: state.error ?? 'Failed to update test',
            );
          }
          
          setState(() {
            _isUpdating = state.isLoading;
          });
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEditNotice(),
                const SizedBox(height: 24),
                _buildBasicInfoSection(),
                const SizedBox(height: 32),
                _buildSettingsSection(),
                const SizedBox(height: 32),
                _buildImageSection(),
                const SizedBox(height: 32),
                _buildQuestionsSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditNotice() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.edit, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _languageCubit.getLocalizedText(
                korean: '기존 시험을 편집하고 있습니다',
                english: 'Editing existing test',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _languageCubit.getLocalizedText(
            korean: '기본 정보',
            english: 'Basic Information',
          ),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: _languageCubit.getLocalizedText(
              korean: '시험 제목',
              english: 'Test Title',
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return _languageCubit.getLocalizedText(
                korean: '제목을 입력해주세요',
                english: 'Please enter a title',
              );
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: _languageCubit.getLocalizedText(
              korean: '설명',
              english: 'Description',
            ),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return _languageCubit.getLocalizedText(
                korean: '설명을 입력해주세요',
                english: 'Please enter a description',
              );
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _languageCubit.getLocalizedText(
            korean: '시험 설정',
            english: 'Test Settings',
          ),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<BookLevel>(
                value: _selectedLevel,
                decoration: InputDecoration(
                  labelText: _languageCubit.getLocalizedText(
                    korean: '난이도',
                    english: 'Level',
                  ),
                ),
                items: BookLevel.values.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level.getName(_languageCubit)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedLevel = value;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<TestCategory>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: _languageCubit.getLocalizedText(
                    korean: '카테고리',
                    english: 'Category',
                  ),
                ),
                items: TestCategory.values
                    .where((cat) => cat != TestCategory.all)
                    .map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _timeLimitController,
                decoration: InputDecoration(
                  labelText: _languageCubit.getLocalizedText(
                    korean: '제한 시간 (분)',
                    english: 'Time Limit (minutes)',
                  ),
                  hintText: '0 = 무제한',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final timeLimit = int.tryParse(value);
                    if (timeLimit == null || timeLimit < 0) {
                      return _languageCubit.getLocalizedText(
                        korean: '올바른 숫자를 입력해주세요',
                        english: 'Please enter a valid number',
                      );
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _passingScoreController,
                decoration: InputDecoration(
                  labelText: _languageCubit.getLocalizedText(
                    korean: '합격 점수 (%)',
                    english: 'Passing Score (%)',
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return _languageCubit.getLocalizedText(
                      korean: '합격 점수를 입력해주세요',
                      english: 'Please enter passing score',
                    );
                  }
                  final score = int.tryParse(value);
                  if (score == null || score < 0 || score > 100) {
                    return _languageCubit.getLocalizedText(
                      korean: '0-100 사이의 숫자를 입력해주세요',
                      english: 'Please enter a number between 0-100',
                    );
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        SwitchListTile(
          title: Text(
            _languageCubit.getLocalizedText(
              korean: '시험 공개',
              english: 'Publish Test',
            ),
          ),
          subtitle: Text(
            _languageCubit.getLocalizedText(
              korean: '다른 사용자가 이 시험을 볼 수 있습니다',
              english: 'Other users can access this test',
            ),
          ),
          value: _isPublished,
          onChanged: (value) {
            setState(() {
              _isPublished = value;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _languageCubit.getLocalizedText(
            korean: '커버 이미지',
            english: 'Cover Image',
          ),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        if (_selectedImage != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          )
        else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _currentImageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Icon(Icons.broken_image)),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentImageUrl = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 40,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _languageCubit.getLocalizedText(
                      korean: '이미지 추가',
                      english: 'Add Image',
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionsSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _languageCubit.getLocalizedText(
                korean: '문제',
                english: 'Questions',
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _questions.isEmpty 
                    ? colorScheme.errorContainer.withOpacity(0.3)
                    : colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_questions.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _questions.isEmpty 
                      ? colorScheme.onErrorContainer
                      : colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_questions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  _languageCubit.getLocalizedText(
                    korean: '아직 문제가 없습니다',
                    english: 'No questions yet',
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    _languageCubit.getLocalizedText(
                      korean: '첫 번째 문제 추가',
                      english: 'Add First Question',
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          ...List.generate(_questions.length, (index) {
            final question = _questions[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.question.isNotEmpty 
                              ? question.question 
                              : _languageCubit.getLocalizedText(korean: '이미지 문제', english: 'Image Question'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${question.options.length} ${_languageCubit.getLocalizedText(korean: '선택지', english: 'options')}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (question.hasQuestionImage) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'IMG',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
                    onPressed: () => _editQuestion(index),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    onPressed: () => _deleteQuestion(index),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                _languageCubit.getLocalizedText(
                  korean: '문제 추가',
                  english: 'Add Question',
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _currentImageUrl = null;
      });
    }
  }

  void _addQuestion() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuestionEditorPage(
          onSave: (newQuestion) {
            setState(() {
              _questions.add(newQuestion);
            });
          },
          languageCubit: _languageCubit,
          snackBarCubit: _snackBarCubit,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _editQuestion(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuestionEditorPage(
          question: _questions[index],
          onSave: (updatedQuestion) {
            setState(() {
              _questions[index] = updatedQuestion;
            });
          },
          languageCubit: _languageCubit,
          snackBarCubit: _snackBarCubit,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _languageCubit.getLocalizedText(
            korean: '문제 삭제',
            english: 'Delete Question',
          ),
        ),
        content: Text(
          _languageCubit.getLocalizedText(
            korean: '이 문제를 삭제하시겠습니까?',
            english: 'Are you sure you want to delete this question?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _languageCubit.getLocalizedText(
                korean: '취소',
                english: 'Cancel',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _questions.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(
              _languageCubit.getLocalizedText(
                korean: '삭제',
                english: 'Delete',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_questions.isEmpty) {
      _snackBarCubit.showErrorLocalized(
        korean: '최소 1개의 문제를 추가해주세요',
        english: 'Please add at least one question',
      );
      return;
    }

    try {
      final timeLimit = int.tryParse(_timeLimitController.text) ?? 0;
      final passingScore = int.parse(_passingScoreController.text);

      final updatedTest = _originalTest!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        questions: _questions,
        timeLimit: timeLimit,
        passingScore: passingScore,
        level: _selectedLevel,
        category: _selectedCategory,
        language: _selectedLanguage,
        icon: _selectedIcon,
        isPublished: _isPublished,
        updatedAt: DateTime.now(),
        imageUrl: _selectedImage != null ? null : _currentImageUrl,
        imagePath: _selectedImage != null ? null : _originalTest!.imagePath,
      );

      await _testUploadCubit.updateExistingTest(
        widget.testId, 
        updatedTest, 
        imageFile: _selectedImage,
      );

    } catch (e) {
      _snackBarCubit.showErrorLocalized(
        korean: '시험 수정 중 오류가 발생했습니다: $e',
        english: 'Error updating test: $e',
      );
    }
  }
}