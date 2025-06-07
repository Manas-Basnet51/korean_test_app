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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _languageCubit.getLocalizedText(
              korean: '시험 편집',
              english: 'Edit Test',
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _languageCubit.getLocalizedText(
            korean: '시험 편집',
            english: 'Edit Test',
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isUpdating ? null : _updateTest,
            child: Text(
              _languageCubit.getLocalizedText(
                korean: '저장',
                english: 'Save',
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                _buildSettingsSection(),
                const SizedBox(height: 24),
                _buildImageSection(),
                const SizedBox(height: 24),
                _buildQuestionsSection(),
                const SizedBox(height: 32),
                if (_isUpdating) _buildUpdatingIndicator(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuestion,
        tooltip: _languageCubit.getLocalizedText(
          korean: '문제 추가',
          english: 'Add Question',
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _languageCubit.getLocalizedText(
                korean: '기본 정보',
                english: 'Basic Information',
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _languageCubit.getLocalizedText(
                korean: '시험 설정',
                english: 'Test Settings',
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
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
            
            const SizedBox(height: 16),
            
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
                  english: 'Other users can see this test',
                ),
              ),
              value: _isPublished,
              onChanged: (value) {
                setState(() {
                  _isPublished = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _languageCubit.getLocalizedText(
                korean: '시험 이미지',
                english: 'Test Image',
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
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
                    child: CircleAvatar(
                      backgroundColor: Colors.red,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                          });
                        },
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
                    child: CircleAvatar(
                      backgroundColor: Colors.red,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _currentImageUrl = null;
                          });
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              )
            else
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 8),
                      Text(
                        _languageCubit.getLocalizedText(
                          korean: '이미지 선택 (선택사항)',
                          english: 'Select Image (Optional)',
                        ),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _languageCubit.getLocalizedText(
                    korean: '문제 목록',
                    english: 'Questions',
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_questions.length} ${_languageCubit.getLocalizedText(korean: '문제', english: 'questions')}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_questions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.quiz_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _languageCubit.getLocalizedText(
                        korean: '아직 문제가 없습니다',
                        english: 'No questions yet',
                      ),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_questions.length, (index) {
                final question = _questions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                    ),
                    title: Text(
                      question.question,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${question.options.length} ${_languageCubit.getLocalizedText(korean: '선택지', english: 'options')}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editQuestion(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteQuestion(index),
                        ),
                      ],
                    ),
                    onTap: () => _editQuestion(index),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdatingIndicator() {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _languageCubit.getLocalizedText(
              korean: '시험을 업데이트하는 중...',
              english: 'Updating test...',
            ),
          ),
        ],
      ),
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
    _showQuestionDialog();
  }

  void _editQuestion(int index) {
    _showQuestionDialog(question: _questions[index], index: index);
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

  void _showQuestionDialog({TestQuestion? question, int? index}) {
    final questionController = TextEditingController(text: question?.question ?? '');
    final explanationController = TextEditingController(text: question?.explanation ?? '');
    final optionControllers = List.generate(4, (i) {
      if (question?.options != null && question!.options.length > i) {
        return TextEditingController(text: question.options[i]);
      } else {
        return TextEditingController(text: '');
      }
    });
    
    int correctAnswer = question?.correctAnswerIndex ?? 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            index != null 
                ? _languageCubit.getLocalizedText(korean: '문제 수정', english: 'Edit Question')
                : _languageCubit.getLocalizedText(korean: '문제 추가', english: 'Add Question'),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: questionController,
                    decoration: InputDecoration(
                      labelText: _languageCubit.getLocalizedText(korean: '문제', english: 'Question'),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  
                  ...List.generate(4, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: i,
                          groupValue: correctAnswer,
                          onChanged: (value) {
                            setDialogState(() {
                              correctAnswer = value!;
                            });
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: optionControllers[i],
                            decoration: InputDecoration(
                              labelText: '${_languageCubit.getLocalizedText(korean: '선택지', english: 'Option')} ${i + 1}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  
                  const SizedBox(height: 16),
                  TextField(
                    controller: explanationController,
                    decoration: InputDecoration(
                      labelText: _languageCubit.getLocalizedText(korean: '설명 (선택사항)', english: 'Explanation (Optional)'),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                _languageCubit.getLocalizedText(korean: '취소', english: 'Cancel'),
              ),
            ),
            TextButton(
              onPressed: () {
                if (questionController.text.trim().isEmpty) {
                  _snackBarCubit.showErrorLocalized(
                    korean: '문제를 입력해주세요',
                    english: 'Please enter a question',
                  );
                  return;
                }
                
                final options = optionControllers.map((c) => c.text.trim()).toList();
                if (options.any((option) => option.isEmpty)) {
                  _snackBarCubit.showErrorLocalized(
                    korean: '모든 선택지를 입력해주세요',
                    english: 'Please fill in all options',
                  );
                  return;
                }

                final newQuestion = TestQuestion(
                  id: question?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  question: questionController.text.trim(),
                  options: options,
                  correctAnswerIndex: correctAnswer,
                  explanation: explanationController.text.trim().isEmpty 
                      ? null 
                      : explanationController.text.trim(),
                );

                setState(() {
                  if (index != null) {
                    _questions[index] = newQuestion;
                  } else {
                    _questions.add(newQuestion);
                  }
                });

                Navigator.pop(context);
              },
              child: Text(
                index != null 
                    ? _languageCubit.getLocalizedText(korean: '수정', english: 'Update')
                    : _languageCubit.getLocalizedText(korean: '추가', english: 'Add'),
              ),
            ),
          ],
        ),
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

      // Update test with image atomically
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