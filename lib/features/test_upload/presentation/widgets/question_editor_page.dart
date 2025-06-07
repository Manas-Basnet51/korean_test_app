import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:korean_language_app/core/enums/question_type.dart';
import 'package:korean_language_app/core/models/test_question.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';
import 'package:korean_language_app/core/presentation/snackbar/bloc/snackbar_cubit.dart';

class QuestionEditorPage extends StatefulWidget {
  final TestQuestion? question;
  final Function(TestQuestion) onSave;
  final LanguagePreferenceCubit languageCubit;
  final SnackBarCubit snackBarCubit;

  const QuestionEditorPage({super.key, 
    this.question,
    required this.onSave,
    required this.languageCubit,
    required this.snackBarCubit,
  });

  @override
  State<QuestionEditorPage> createState() => QuestionEditorPageState();
}

class QuestionEditorPageState extends State<QuestionEditorPage> {
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
    
    if (_selectedQuestionType.hasQuestionImage && _questionImage == null && widget.question?.questionImagePath == null) {
      widget.snackBarCubit.showErrorLocalized(
        korean: '문제 이미지를 선택해주세요',
        english: 'Please select a question image',
      );
      return;
    }

    // Validate options
    for (int i = 0; i < 4; i++) {
      if (_options[i].isImage) {
        if (_answerImages[i] == null && widget.question?.options[i].imagePath == null) {
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
          imagePath: _answerImages[i]?.path ?? widget.question?.options[i].imagePath,
          imageUrl: widget.question?.options[i].imageUrl,
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