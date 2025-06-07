import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:korean_language_app/core/enums/book_level.dart';
import 'package:korean_language_app/core/enums/test_category.dart';
import 'package:korean_language_app/core/enums/question_type.dart';
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
                korean: '시험 커버 이미지',
                english: 'Test Cover Image',
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
                          korean: '커버 이미지 선택 (선택사항)',
                          english: 'Select Cover Image (Optional)',
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
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            question.question.isNotEmpty 
                                ? question.question 
                                : _languageCubit.getLocalizedText(korean: '이미지 문제', english: 'Image Question'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (question.hasQuestionImage)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(Icons.image, size: 16, color: Colors.blue),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(question.questionType.displayName),
                        Text('${question.options.length} ${_languageCubit.getLocalizedText(korean: '선택지', english: 'options')}'),
                      ],
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _QuestionEditorPage(
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
        builder: (context) => _QuestionEditorPage(
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

// Reuse the same QuestionEditorPage from the upload page
class _QuestionEditorPage extends StatefulWidget {
  final TestQuestion? question;
  final Function(TestQuestion) onSave;
  final LanguagePreferenceCubit languageCubit;
  final SnackBarCubit snackBarCubit;

  const _QuestionEditorPage({
    this.question,
    required this.onSave,
    required this.languageCubit,
    required this.snackBarCubit,
  });

  @override
  State<_QuestionEditorPage> createState() => _QuestionEditorPageState();
}

class _QuestionEditorPageState extends State<_QuestionEditorPage> {
  final _questionController = TextEditingController();
  final _explanationController = TextEditingController();
  final _optionControllers = List.generate(4, (i) => TextEditingController());
  
  QuestionType _selectedQuestionType = QuestionType.textQuestion_textAnswers;
  int _correctAnswer = 0;
  File? _questionImage;
  final List<File?> _answerImages = List.generate(4, (i) => null);
  final List<AnswerOption> _options = [];
  
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      _populateFields(widget.question!);
    } else {
      _initializeEmptyOptions();
    }
  }

  void _populateFields(TestQuestion question) {
    _questionController.text = question.question;
    _explanationController.text = question.explanation ?? '';
    _selectedQuestionType = question.questionType;
    _correctAnswer = question.correctAnswerIndex;
    
    for (int i = 0; i < question.options.length && i < 4; i++) {
      _optionControllers[i].text = question.options[i].text;
      _options.add(question.options[i]);
    }
    
    while (_options.length < 4) {
      _options.add(const AnswerOption(text: '', isImage: false));
    }
  }

  void _initializeEmptyOptions() {
    for (int i = 0; i < 4; i++) {
      _options.add(const AnswerOption(text: '', isImage: false));
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.question != null 
              ? widget.languageCubit.getLocalizedText(korean: '문제 수정', english: 'Edit Question')
              : widget.languageCubit.getLocalizedText(korean: '문제 추가', english: 'Add Question'),
        ),
        actions: [
          TextButton(
            onPressed: _saveQuestion,
            child: Text(
              widget.languageCubit.getLocalizedText(korean: '저장', english: 'Save'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionTypeSection(),
            const SizedBox(height: 24),
            _buildQuestionSection(),
            const SizedBox(height: 24),
            _buildOptionsSection(),
            const SizedBox(height: 24),
            _buildExplanationSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.languageCubit.getLocalizedText(korean: '문제 유형', english: 'Question Type'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<QuestionType>(
              value: _selectedQuestionType,
              decoration: InputDecoration(
                labelText: widget.languageCubit.getLocalizedText(korean: '유형 선택', english: 'Select Type'),
              ),
              items: QuestionType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedQuestionType = value;
                    _updateOptionsForType();
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.languageCubit.getLocalizedText(korean: '문제', english: 'Question'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (_selectedQuestionType.hasQuestionImage) ...[
              if (_questionImage != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _questionImage!,
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
                              _questionImage = null;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                )
              else if (widget.question?.questionImageUrl != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.question!.questionImageUrl!,
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
                        backgroundColor: Colors.blue,
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () => _pickQuestionImage(),
                        ),
                      ),
                    ),
                  ],
                )
              else
                InkWell(
                  onTap: () => _pickQuestionImage(),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[600]),
                        const SizedBox(height: 8),
                        Text(
                          widget.languageCubit.getLocalizedText(
                            korean: '문제 이미지 선택',
                            english: 'Select Question Image',
                          ),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
            
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                labelText: _selectedQuestionType.hasQuestionImage
                    ? widget.languageCubit.getLocalizedText(korean: '문제 설명 (선택사항)', english: 'Question Description (Optional)')
                    : widget.languageCubit.getLocalizedText(korean: '문제', english: 'Question'),
                hintText: _selectedQuestionType.hasQuestionImage
                    ? widget.languageCubit.getLocalizedText(korean: '이미지에 대한 추가 설명', english: 'Additional description for the image')
                    : widget.languageCubit.getLocalizedText(korean: '문제를 입력하세요', english: 'Enter your question'),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.languageCubit.getLocalizedText(korean: '선택지', english: 'Answer Options'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ...List.generate(4, (index) => _buildOptionTile(index)),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(int index) {
    final shouldShowImageOption = _selectedQuestionType.hasAnswerImages || 
                                  _selectedQuestionType.supportsMixedAnswers;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: _correctAnswer == index ? Colors.green.withOpacity(0.1) : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Radio<int>(
                value: index,
                groupValue: _correctAnswer,
                onChanged: (value) {
                  setState(() {
                    _correctAnswer = value!;
                  });
                },
              ),
              Expanded(
                child: Text(
                  '${widget.languageCubit.getLocalizedText(korean: '선택지', english: 'Option')} ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              if (shouldShowImageOption)
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _setOptionAsText(index),
                      icon: const Icon(Icons.text_fields, size: 16),
                      label: Text(
                        widget.languageCubit.getLocalizedText(korean: '텍스트', english: 'Text'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: !_options[index].isImage ? Colors.blue.withOpacity(0.1) : null,
                        minimumSize: const Size(60, 30),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _setOptionAsImage(index),
                      icon: const Icon(Icons.image, size: 16),
                      label: Text(
                        widget.languageCubit.getLocalizedText(korean: '이미지', english: 'Image'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: _options[index].isImage ? Colors.blue.withOpacity(0.1) : null,
                        minimumSize: const Size(60, 30),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          if (_options[index].isImage) ...[
            if (_answerImages[index] != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _answerImages[index]!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.red,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 16,
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _answerImages[index] = null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              )
            else if (widget.question?.options != null && 
                     index < widget.question!.options.length && 
                     widget.question!.options[index].imageUrl != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.question!.options[index].imageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(child: Icon(Icons.broken_image)),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.blue,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 16,
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () => _pickAnswerImage(index),
                      ),
                    ),
                  ),
                ],
              )
            else
              InkWell(
                onTap: () => _pickAnswerImage(index),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, color: Colors.grey[600]),
                      const SizedBox(height: 4),
                      Text(
                        widget.languageCubit.getLocalizedText(
                          korean: '이미지 선택',
                          english: 'Select Image',
                        ),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ] else ...[
            TextField(
              controller: _optionControllers[index],
              decoration: InputDecoration(
                hintText: widget.languageCubit.getLocalizedText(
                  korean: '선택지 텍스트를 입력하세요',
                  english: 'Enter option text',
                ),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                _options[index] = _options[index].copyWith(text: value);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExplanationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.languageCubit.getLocalizedText(korean: '설명', english: 'Explanation'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _explanationController,
              decoration: InputDecoration(
                labelText: widget.languageCubit.getLocalizedText(korean: '정답 설명 (선택사항)', english: 'Answer Explanation (Optional)'),
                hintText: widget.languageCubit.getLocalizedText(korean: '정답에 대한 설명을 입력하세요', english: 'Enter explanation for the correct answer'),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  void _updateOptionsForType() {
    for (int i = 0; i < 4; i++) {
      if (_selectedQuestionType.hasAnswerImages && !_selectedQuestionType.supportsMixedAnswers) {
        _options[i] = _options[i].copyWith(isImage: true, text: '');
        _optionControllers[i].clear();
      } else if (!_selectedQuestionType.hasAnswerImages && !_selectedQuestionType.supportsMixedAnswers) {
        _options[i] = _options[i].copyWith(isImage: false);
        _answerImages[i] = null;
      }
    }
  }

  void _setOptionAsText(int index) {
    setState(() {
      _options[index] = _options[index].copyWith(isImage: false);
      _answerImages[index] = null;
    });
  }

  void _setOptionAsImage(int index) {
    setState(() {
      _options[index] = _options[index].copyWith(isImage: true, text: '');
      _optionControllers[index].clear();
    });
  }

  Future<void> _pickQuestionImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _questionImage = File(image.path);
      });
    }
  }

  Future<void> _pickAnswerImage(int index) async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _answerImages[index] = File(image.path);
      });
    }
  }

  void _saveQuestion() {
    // Validate question
    if (!_selectedQuestionType.hasQuestionImage && _questionController.text.trim().isEmpty) {
      widget.snackBarCubit.showErrorLocalized(
        korean: '문제를 입력해주세요',
        english: 'Please enter a question',
      );
      return;
    }
    
    if (_selectedQuestionType.hasQuestionImage && 
        _questionImage == null && 
        (widget.question?.questionImagePath == null && widget.question?.questionImageUrl == null)) {
      widget.snackBarCubit.showErrorLocalized(
        korean: '문제 이미지를 선택해주세요',
        english: 'Please select a question image',
      );
      return;
    }

    // Validate options
    for (int i = 0; i < 4; i++) {
      if (_options[i].isImage) {
        if (_answerImages[i] == null && 
            (widget.question?.options == null || 
             i >= widget.question!.options.length || 
             (widget.question!.options[i].imagePath == null && widget.question!.options[i].imageUrl == null))) {
          widget.snackBarCubit.showErrorLocalized(
            korean: '모든 이미지 선택지를 선택해주세요',
            english: 'Please select all image options',
          );
          return;
        }
      } else {
        if (_optionControllers[i].text.trim().isEmpty) {
          widget.snackBarCubit.showErrorLocalized(
            korean: '모든 텍스트 선택지를 입력해주세요',
            english: 'Please enter all text options',
          );
          return;
        }
      }
    }

    // Create updated options
    final updatedOptions = <AnswerOption>[];
    for (int i = 0; i < 4; i++) {
      if (_options[i].isImage) {
        updatedOptions.add(AnswerOption(
          text: '',
          isImage: true,
          imagePath: _answerImages[i]?.path ?? 
                     (widget.question != null && i < widget.question!.options.length 
                         ? widget.question!.options[i].imagePath 
                         : null),
          imageUrl: widget.question != null && i < widget.question!.options.length 
                       ? widget.question!.options[i].imageUrl 
                       : null,
        ));
      } else {
        updatedOptions.add(AnswerOption(
          text: _optionControllers[i].text.trim(),
          isImage: false,
        ));
      }
    }

    final newQuestion = TestQuestion(
      id: widget.question?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      question: _questionController.text.trim(),
      questionImagePath: _questionImage?.path ?? widget.question?.questionImagePath,
      questionImageUrl: widget.question?.questionImageUrl,
      options: updatedOptions,
      correctAnswerIndex: _correctAnswer,
      explanation: _explanationController.text.trim().isEmpty 
          ? null 
          : _explanationController.text.trim(),
      questionType: _selectedQuestionType,
    );

    widget.onSave(newQuestion);
    Navigator.pop(context);
  }
}