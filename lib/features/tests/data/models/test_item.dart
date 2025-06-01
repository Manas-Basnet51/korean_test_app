import 'package:flutter/material.dart';
import 'package:korean_language_app/core/enums/book_level.dart';
import 'package:korean_language_app/core/enums/test_category.dart';
import 'package:korean_language_app/features/tests/data/models/test_question.dart';

class TestItem {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? imagePath;
  final List<TestQuestion> questions;
  final int timeLimit; // in minutes, 0 means no limit
  final int passingScore; // percentage required to pass
  final BookLevel level;
  final TestCategory category;
  final String language;
  final IconData icon;
  final String? creatorUid;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isPublished;
  final Map<String, dynamic>? metadata;

  const TestItem({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.imagePath,
    required this.questions,
    this.timeLimit = 0,
    this.passingScore = 60,
    required this.level,
    required this.category,
    this.language = 'Korean',
    this.icon = Icons.quiz,
    this.creatorUid,
    this.createdAt,
    this.updatedAt,
    this.isPublished = true,
    this.metadata,
  });

  TestItem copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? imagePath,
    List<TestQuestion>? questions,
    int? timeLimit,
    int? passingScore,
    BookLevel? level,
    TestCategory? category,
    String? language,
    IconData? icon,
    String? creatorUid,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublished,
    Map<String, dynamic>? metadata,
  }) {
    return TestItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      questions: questions ?? this.questions,
      timeLimit: timeLimit ?? this.timeLimit,
      passingScore: passingScore ?? this.passingScore,
      level: level ?? this.level,
      category: category ?? this.category,
      language: language ?? this.language,
      icon: icon ?? this.icon,
      creatorUid: creatorUid ?? this.creatorUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublished: isPublished ?? this.isPublished,
      metadata: metadata ?? this.metadata,
    );
  }

  int get questionCount => questions.length;
  int get totalTimeLimit => timeLimit;
  String get formattedTimeLimit => timeLimit > 0 ? '$timeLimit분' : '무제한';
  String get formattedPassingScore => '$passingScore%';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  factory TestItem.fromJson(Map<String, dynamic> json) {
    BookLevel level;
    if (json['level'] is int) {
      level = BookLevel.values[json['level']];
    } else if (json['level'] is String) {
      level = BookLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['level'],
        orElse: () => BookLevel.beginner,
      );
    } else {
      level = BookLevel.beginner;
    }

    TestCategory category;
    if (json['category'] is int) {
      category = TestCategory.values[json['category']];
    } else if (json['category'] is String) {
      category = TestCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => TestCategory.practice,
      );
    } else {
      category = TestCategory.practice;
    }

    IconData icon;
    if (json['iconCodePoint'] != null) {
      icon = _iconMapping[json['iconCodePoint']] ?? Icons.quiz;
    } else {
      icon = Icons.quiz;
    }

    DateTime? createdAt;
    if (json['createdAt'] != null) {
      if (json['createdAt'] is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(json['createdAt']);
      } else if (json['createdAt'] is Map) {
        final seconds = json['createdAt']['_seconds'] as int?;
        if (seconds != null) {
          createdAt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      }
    }

    DateTime? updatedAt;
    if (json['updatedAt'] != null) {
      if (json['updatedAt'] is int) {
        updatedAt = DateTime.fromMillisecondsSinceEpoch(json['updatedAt']);
      } else if (json['updatedAt'] is Map) {
        final seconds = json['updatedAt']['_seconds'] as int?;
        if (seconds != null) {
          updatedAt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      }
    }

    List<TestQuestion> questions = [];
    if (json['questions'] is List) {
      questions = (json['questions'] as List)
          .map((q) => TestQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
    }

    return TestItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      imagePath: json['imagePath'] as String?,
      questions: questions,
      timeLimit: json['timeLimit'] as int? ?? 0,
      passingScore: json['passingScore'] as int? ?? 60,
      level: level,
      category: category,
      language: json['language'] as String? ?? 'Korean',
      icon: icon,
      creatorUid: json['creatorUid'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPublished: json['isPublished'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'questions': questions.map((q) => q.toJson()).toList(),
      'timeLimit': timeLimit,
      'passingScore': passingScore,
      'level': level.toString().split('.').last,
      'category': category.toString().split('.').last,
      'language': language,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'creatorUid': creatorUid,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'isPublished': isPublished,
      'metadata': metadata,
    };
  }

  static final Map<int, IconData> _iconMapping = {
    Icons.quiz.codePoint: Icons.quiz,
    Icons.school.codePoint: Icons.school,
    Icons.assignment.codePoint: Icons.assignment,
    Icons.fact_check.codePoint: Icons.fact_check,
    Icons.psychology.codePoint: Icons.psychology,
    Icons.edit_note.codePoint: Icons.edit_note,
    Icons.help_outline.codePoint: Icons.help_outline,
  };
}