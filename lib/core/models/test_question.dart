import 'package:equatable/equatable.dart';
import 'package:korean_language_app/core/enums/question_type.dart';

class TestQuestion extends Equatable {
  final String id;
  final String question;
  final String? questionImageUrl;
  final String? questionImagePath;
  final List<AnswerOption> options;
  final int correctAnswerIndex;
  final String? explanation;
  final QuestionType questionType;
  final int timeLimit; // in seconds, 0 means no limit
  final Map<String, dynamic>? metadata;

  const TestQuestion({
    required this.id,
    required this.question,
    this.questionImageUrl,
    this.questionImagePath,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
    this.questionType = QuestionType.textQuestion_textAnswers,
    this.timeLimit = 0,
    this.metadata,
  });

  TestQuestion copyWith({
    String? id,
    String? question,
    String? questionImageUrl,
    String? questionImagePath,
    List<AnswerOption>? options,
    int? correctAnswerIndex,
    String? explanation,
    QuestionType? questionType,
    int? timeLimit,
    Map<String, dynamic>? metadata,
  }) {
    return TestQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      questionImageUrl: questionImageUrl ?? this.questionImageUrl,
      questionImagePath: questionImagePath ?? this.questionImagePath,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      explanation: explanation ?? this.explanation,
      questionType: questionType ?? this.questionType,
      timeLimit: timeLimit ?? this.timeLimit,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper getters
  bool get hasQuestionImage => questionImageUrl != null && questionImageUrl!.isNotEmpty;
  bool get hasImageAnswers => options.any((option) => option.isImage);
  
  // Get text-only options for backward compatibility
  List<String> get textOptions => options.map((option) => option.text).toList();

  factory TestQuestion.fromJson(Map<String, dynamic> json) {
    QuestionType questionType = QuestionType.textQuestion_textAnswers;
    if (json['questionType'] is String) {
      questionType = QuestionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['questionType'],
        orElse: () => QuestionType.textQuestion_textAnswers,
      );
    }

    List<AnswerOption> options = [];
    if (json['options'] is List) {
      final optionsList = json['options'] as List;
      
      // Check if it's the old format (List<String>) or new format (List<AnswerOption>)
      if (optionsList.isNotEmpty) {
        if (optionsList.first is String) {
          // Old format - convert to AnswerOption
          options = optionsList.map((option) => AnswerOption(
            text: option as String,
            isImage: false,
          )).toList();
        } else {
          // New format
          options = optionsList
              .map((option) => AnswerOption.fromJson(option as Map<String, dynamic>))
              .toList();
        }
      }
    }

    return TestQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      questionImageUrl: json['questionImageUrl'] as String?,
      questionImagePath: json['questionImagePath'] as String?,
      options: options,
      correctAnswerIndex: json['correctAnswerIndex'] as int,
      explanation: json['explanation'] as String?,
      questionType: questionType,
      timeLimit: json['timeLimit'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'questionImageUrl': questionImageUrl,
      'questionImagePath': questionImagePath,
      'options': options.map((option) => option.toJson()).toList(),
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
      'questionType': questionType.toString().split('.').last,
      'timeLimit': timeLimit,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        question,
        questionImageUrl,
        questionImagePath,
        options,
        correctAnswerIndex,
        explanation,
        questionType,
        timeLimit,
        metadata,
      ];
}