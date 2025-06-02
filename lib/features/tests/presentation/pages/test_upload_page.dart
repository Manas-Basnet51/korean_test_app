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
import 'package:korean_language_app/features/tests/data/models/test_item.dart';
import 'package:korean_language_app/features/tests/data/models/test_question.dart';
import 'package:korean_language_app/features/tests/presentation/bloc/tests_cubit.dart';

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
  
  TestsCubit get _testsCubit => context.read<TestsCubit>();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _languageCubit.getLocalizedText(
            korean: '시험 만들기',
            english: 'Create Test',
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _uploadTest,
            child: Text(
              _languageCubit.getLocalizedText(
                korean: '업로드',
                english: 'Upload',
              ),
            ),
          ),
        ],
      ),
      body: Form(
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
              if (_isUploading) _buildUploadingIndicator(),
            ],
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
                hintText: _languageCubit.getLocalizedText(
                  korean: '시험 제목을 입력하세요',
                  english: 'Enter test title',
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
                hintText: _languageCubit.getLocalizedText(
                  korean: '시험에 대한 설명을 입력하세요',
                  english: 'Enter test description',
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
                    const SizedBox(height: 8),
                    Text(
                      _languageCubit.getLocalizedText(
                        korean: '+ 버튼을 눌러 문제를 추가하세요',
                        english: 'Tap the + button to add questions',
                      ),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
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

  Widget _buildUploadingIndicator() {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _languageCubit.getLocalizedText(
              korean: '시험을 업로드하는 중...',
              english: 'Uploading test...',
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
    final optionControllers = List.generate(4, (i) => 
        TextEditingController(text: question?.options[i] ?? ''));
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

    setState(() {
      _isUploading = true;
    });

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
      );

      // Upload test using TestsCubit
      final success = await _testsCubit.uploadNewTest(test);
      
      if (success) {
        _snackBarCubit.showSuccessLocalized(
          korean: '시험이 성공적으로 업로드되었습니다',
          english: 'Test uploaded successfully',
        );

        // Navigate back to tests page
        context.go('/tests');
      } else {
        _snackBarCubit.showErrorLocalized(
          korean: '시험 업로드에 실패했습니다',
          english: 'Failed to upload test',
        );
      }

    } catch (e) {
      _snackBarCubit.showErrorLocalized(
        korean: '시험 업로드 중 오류가 발생했습니다: $e',
        english: 'Error uploading test: $e',
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
}