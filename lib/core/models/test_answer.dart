import 'package:equatable/equatable.dart';

class TestAnswer extends Equatable {
  final String questionId;
  final int selectedAnswerIndex;
  final bool isCorrect;
  final int timeSpent; // in seconds

  const TestAnswer({
    required this.questionId,
    required this.selectedAnswerIndex,
    required this.isCorrect,
    required this.timeSpent,
  });

  factory TestAnswer.fromJson(Map<String, dynamic> json) {
    return TestAnswer(
      questionId: json['questionId'] as String,
      selectedAnswerIndex: json['selectedAnswerIndex'] as int,
      isCorrect: json['isCorrect'] as bool,
      timeSpent: json['timeSpent'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedAnswerIndex': selectedAnswerIndex,
      'isCorrect': isCorrect,
      'timeSpent': timeSpent,
    };
  }

  @override
  List<Object?> get props => [questionId, selectedAnswerIndex, isCorrect, timeSpent];
}

