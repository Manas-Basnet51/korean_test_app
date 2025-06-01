import 'package:equatable/equatable.dart';

class TestQuestion extends Equatable {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;
  final String? imageUrl;
  final int timeLimit; // in seconds, 0 means no limit
  final Map<String, dynamic>? metadata;

  const TestQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
    this.imageUrl,
    this.timeLimit = 0,
    this.metadata,
  });

  TestQuestion copyWith({
    String? id,
    String? question,
    List<String>? options,
    int? correctAnswerIndex,
    String? explanation,
    String? imageUrl,
    int? timeLimit,
    Map<String, dynamic>? metadata,
  }) {
    return TestQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      explanation: explanation ?? this.explanation,
      imageUrl: imageUrl ?? this.imageUrl,
      timeLimit: timeLimit ?? this.timeLimit,
      metadata: metadata ?? this.metadata,
    );
  }

  factory TestQuestion.fromJson(Map<String, dynamic> json) {
    return TestQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswerIndex: json['correctAnswerIndex'] as int,
      explanation: json['explanation'] as String?,
      imageUrl: json['imageUrl'] as String?,
      timeLimit: json['timeLimit'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
      'imageUrl': imageUrl,
      'timeLimit': timeLimit,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        question,
        options,
        correctAnswerIndex,
        explanation,
        imageUrl,
        timeLimit,
        metadata,
      ];
}