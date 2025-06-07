import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:korean_language_app/core/enums/book_level.dart';
import 'package:korean_language_app/core/enums/test_category.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';
import 'package:korean_language_app/core/presentation/snackbar/bloc/snackbar_cubit.dart';
import 'package:korean_language_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:korean_language_app/features/test_upload/presentation/bloc/test_upload_cubit.dart';
import 'package:korean_language_app/core/models/test_item.dart';
import 'package:korean_language_app/core/models/test_question.dart';
import 'package:korean_language_app/features/test_upload/presentation/widgets/question_editor_page.dart';

class TestUploadPage extends StatefulWidget {
  const TestUploadPage({super.key});

  @override
  State<TestUploadPage> createState() => _TestUploadPageState();
}

class _TestUploadPageState extends State<TestUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeLimitController = TextEditingController();
  final _passingScoreController = TextEditingController(text: '60');
  
  BookLevel _selectedLevel = BookLevel.beginner;
  TestCategory _selectedCategory = TestCategory.practice;
  final String _selectedLanguage = 'Korean';
  final IconData _selectedIcon = Icons.quiz;
  File? _selectedImage;
  bool _isPublished = true;
  
  final List<TestQuestion> _questions = [];
  bool _isUploading = false;
  
  final ImagePicker _imagePicker = ImagePicker();
  
  TestUploadCubit get _testUploadCubit => context.read<TestUploadCubit>();
  LanguagePreferenceCubit get _languageCubit => context.read<LanguagePreferenceCubit>();
  SnackBarCubit get _snackBarCubit => context.read<SnackBarCubit>();
  AuthCubit get _authCubit => context.read<AuthCubit>();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeLimitController.dispose();
    _passingScoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _languageCubit.getLocalizedText(
            korean: '새 시험 만들기',
            english: 'Create Test',
          ),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isUploading ? null : _uploadTest,
              style: TextButton.styleFrom(
                backgroundColor: _isUploading ? Colors.grey.shade300 : colorScheme.primary,
                foregroundColor: _isUploading ? Colors.grey.shade600 : colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isUploading
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
                        korean: '업로드',
                        english: 'Upload',
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
              state.currentOperation.type == TestUploadOperationType.createTest) {
            _snackBarCubit.showSuccessLocalized(
              korean: '시험이 성공적으로 업로드되었습니다',
              english: 'Test uploaded successfully',
            );
            context.go('/tests');
          } else if (state.currentOperation.status == TestUploadOperationStatus.failed) {
            _snackBarCubit.showErrorLocalized(
              korean: state.error ?? '시험 업로드에 실패했습니다',
              english: state.error ?? 'Failed to upload test',
            );
          }
          
          setState(() {
            _isUploading = state.isLoading;
          });
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressSection(),
                const SizedBox(height: 32),
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

  Widget _buildProgressSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    int completedSteps = 0;
    if (_titleController.text.isNotEmpty && _descriptionController.text.isNotEmpty) completedSteps++;
    if (_questions.isNotEmpty) completedSteps++;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _languageCubit.getLocalizedText(
                  korean: '진행 상황',
                  english: 'Progress',
                ),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '$completedSteps/2',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: completedSteps / 2,
            backgroundColor: colorScheme.onSurfaceVariant.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            borderRadius: BorderRadius.circular(4),
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
            hintText: _languageCubit.getLocalizedText(
              korean: '예: 기초 한국어 문법 테스트',
              english: 'e.g. Basic Korean Grammar Test',
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
          onChanged: (value) => setState(() {}),
        ),
        
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: _languageCubit.getLocalizedText(
              korean: '설명',
              english: 'Description',
            ),
            hintText: _languageCubit.getLocalizedText(
              korean: '시험에 대한 설명을 입력하세요',
              english: 'Enter test description',
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
          onChanged: (value) => setState(() {}),
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
            korean: '커버 이미지 (선택사항)',
            english: 'Cover Image (Optional)',
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
                const SizedBox(height: 8),
                Text(
                  _languageCubit.getLocalizedText(
                    korean: '첫 번째 문제를 추가해보세요',
                    english: 'Add your first question to get started',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
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
          onSave: (newQuestion) {
            setState(() {
              _questions[index] = newQuestion;
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

  Future<void> _uploadTest() async {
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

    final authState = _authCubit.state;
    if (authState is! Authenticated) {
      _snackBarCubit.showErrorLocalized(
        korean: '로그인이 필요합니다',
        english: 'Please log in first',
      );
      return;
    }

    try {
      final timeLimit = int.tryParse(_timeLimitController.text) ?? 0;
      final passingScore = int.parse(_passingScoreController.text);

      final test = TestItem(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        questions: _questions,
        timeLimit: timeLimit,
        passingScore: passingScore,
        level: _selectedLevel,
        category: _selectedCategory,
        language: _selectedLanguage,
        icon: _selectedIcon,
        creatorUid: authState.user.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPublished: _isPublished,
        imageUrl: null,
        imagePath: null,
      );

      await _testUploadCubit.uploadNewTest(test, imageFile: _selectedImage);

    } catch (e) {
      _snackBarCubit.showErrorLocalized(
        korean: '시험 업로드 중 오류가 발생했습니다: $e',
        english: 'Error uploading test: $e',
      );
    }
  }
}