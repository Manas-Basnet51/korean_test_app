import 'package:equatable/equatable.dart';
import 'test_answer.dart';

class TestResult extends Equatable {
  final String id;
  final String testId;
  final String userId;
  final String testTitle;
  final List<TestAnswer> answers;
  final int score; // percentage
  final int totalQuestions;
  final int correctAnswers;
  final int totalTimeSpent; // in seconds
  final bool isPassed;
  final DateTime startedAt;
  final DateTime completedAt;
  final Map<String, dynamic>? metadata;

  const TestResult({
    required this.id,
    required this.testId,
    required this.userId,
    required this.testTitle,
    required this.answers,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.totalTimeSpent,
    required this.isPassed,
    required this.startedAt,
    required this.completedAt,
    this.metadata,
  });

  TestResult copyWith({
    String? id,
    String? testId,
    String? userId,
    String? testTitle,
    List<TestAnswer>? answers,
    int? score,
    int? totalQuestions,
    int? correctAnswers,
    int? totalTimeSpent,
    bool? isPassed,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return TestResult(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      userId: userId ?? this.userId,
      testTitle: testTitle ?? this.testTitle,
      answers: answers ?? this.answers,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      isPassed: isPassed ?? this.isPassed,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Duration get totalDuration => completedAt.difference(startedAt);
  String get formattedDuration {
    final duration = totalDuration;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes분 $seconds초';
  }

  String get formattedScore => '$score%';
  String get resultSummary => '$correctAnswers/$totalQuestions ($formattedScore)';

  factory TestResult.fromJson(Map<String, dynamic> json) {
    DateTime startedAt;
    if (json['startedAt'] is int) {
      startedAt = DateTime.fromMillisecondsSinceEpoch(json['startedAt']);
    } else if (json['startedAt'] is Map) {
      final seconds = json['startedAt']['_seconds'] as int;
      startedAt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    } else {
      startedAt = DateTime.now();
    }

    DateTime completedAt;
    if (json['completedAt'] is int) {
      completedAt = DateTime.fromMillisecondsSinceEpoch(json['completedAt']);
    } else if (json['completedAt'] is Map) {
      final seconds = json['completedAt']['_seconds'] as int;
      completedAt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    } else {
      completedAt = DateTime.now();
    }

    List<TestAnswer> answers = [];
    if (json['answers'] is List) {
      answers = (json['answers'] as List)
          .map((a) => TestAnswer.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    return TestResult(
      id: json['id'] as String,
      testId: json['testId'] as String,
      userId: json['userId'] as String,
      testTitle: json['testTitle'] as String,
      answers: answers,
      score: json['score'] as int,
      totalQuestions: json['totalQuestions'] as int,
      correctAnswers: json['correctAnswers'] as int,
      totalTimeSpent: json['totalTimeSpent'] as int,
      isPassed: json['isPassed'] as bool,
      startedAt: startedAt,
      completedAt: completedAt,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testId': testId,
      'userId': userId,
      'testTitle': testTitle,
      'answers': answers.map((a) => a.toJson()).toList(),
      'score': score,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'totalTimeSpent': totalTimeSpent,
      'isPassed': isPassed,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'completedAt': completedAt.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        testId,
        userId,
        testTitle,
        answers,
        score,
        totalQuestions,
        correctAnswers,
        totalTimeSpent,
        isPassed,
        startedAt,
        completedAt,
        metadata,
      ];
}