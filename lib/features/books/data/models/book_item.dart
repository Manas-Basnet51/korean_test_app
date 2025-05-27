import 'package:flutter/material.dart';
import 'package:korean_language_app/core/enums/book_level.dart';
import 'package:korean_language_app/core/enums/course_category.dart';

class BookItem {
  final String id;
  final String title;
  final String description;
  final String? bookImage;
  final String? pdfUrl;
  final String? bookImagePath;
  final String? pdfPath;
  final String duration;
  final int chaptersCount;
  final IconData icon;
  final BookLevel level;
  final CourseCategory courseCategory;
  final String country;
  final String category;
  final String? creatorUid;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BookItem({
    required this.id,
    required this.title,
    required this.description,
    this.bookImage,
    this.pdfUrl,
    this.bookImagePath,
    this.pdfPath,
    required this.duration,
    required this.chaptersCount,
    required this.icon,
    required this.level,
    required this.courseCategory,
    required this.country,
    required this.category,
    this.creatorUid,
    this.createdAt,
    this.updatedAt,
  });

  // Add copyWith method to create a copy with some properties changed
  BookItem copyWith({
    String? id,
    String? title,
    String? description,
    String? bookImage,
    String? pdfUrl,
    String? bookImagePath,
    String? pdfPath,
    String? duration,
    int? chaptersCount,
    IconData? icon,
    BookLevel? level,
    CourseCategory? courseCategory,
    String? country,
    String? category,
    String? creatorUid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      bookImage: bookImage ?? this.bookImage,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      bookImagePath: bookImagePath ?? this.bookImagePath,
      pdfPath: pdfPath ?? this.pdfPath,
      duration: duration ?? this.duration,
      chaptersCount: chaptersCount ?? this.chaptersCount,
      icon: icon ?? this.icon,
      level: level ?? this.level,
      courseCategory: courseCategory ?? this.courseCategory,
      country: country ?? this.country,
      category: category ?? this.category,
      creatorUid: creatorUid ?? this.creatorUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is BookItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  factory BookItem.fromJson(Map<String, dynamic> json) {
    // Handle level conversion
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
    
    // Handle course category conversion
    CourseCategory courseCategory;
    if (json['courseCategory'] is int) {
      courseCategory = CourseCategory.values[json['courseCategory']];
    } else if (json['courseCategory'] is String) {
      courseCategory = CourseCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['courseCategory'],
        orElse: () => CourseCategory.korean,
      );
    } else {
      courseCategory = CourseCategory.korean;
    }
    
    // Handle icon conversion
    IconData icon;
    if (json['iconCodePoint'] != null) {
      icon = _iconMapping[json['iconCodePoint']] ?? Icons.book;
    } else if (json['icon'] is int) {
      final iconData = json['icon'];
      final iconFontFamily = json['iconFontFamily'] as String? ?? 'MaterialIcons';
      icon = IconData(
        iconData,
        fontFamily: iconFontFamily,
        fontPackage: json['iconFontPackage'] as String?,
      );
    } else {
      icon = Icons.book;
    }
    
    // Handle dates
    DateTime? createdAt;
    if (json['createdAt'] != null) {
      if (json['createdAt'] is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(json['createdAt']);
      } else if (json['createdAt'] is Map) {
        // Handle Firestore Timestamp
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
        // Handle Firestore Timestamp
        final seconds = json['updatedAt']['_seconds'] as int?;
        if (seconds != null) {
          updatedAt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      }
    }

    return BookItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      bookImage: json['bookImage'] as String?,
      pdfUrl: json['pdfUrl'] as String?,
      bookImagePath: json['bookImagePath'] as String?,
      pdfPath: json['pdfPath'] as String?,
      duration: json['duration'] as String? ?? '30 mins',
      chaptersCount: json['chaptersCount'] as int? ?? 1,
      icon: icon,
      level: level,
      courseCategory: courseCategory,
      country: json['country'] as String? ?? 'Korea',
      category: json['category'] as String? ?? 'Language',
      creatorUid: json['creatorUid'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'bookImage': bookImage,
      'pdfUrl': pdfUrl,
      'bookImagePath': bookImagePath,
      'pdfPath': pdfPath,
      'duration': duration,
      'chaptersCount': chaptersCount,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'level': level.toString().split('.').last,
      'courseCategory': courseCategory.toString().split('.').last,
      'country': country,
      'category': category,
      'creatorUid': creatorUid,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  static final Map<int, IconData> _iconMapping = {
    // Icons used in your Korean books list
    Icons.menu_book.codePoint: Icons.menu_book,
    Icons.quiz.codePoint: Icons.quiz,
    Icons.business.codePoint: Icons.business,
    Icons.theater_comedy.codePoint: Icons.theater_comedy,
    Icons.record_voice_over.codePoint: Icons.record_voice_over,
    Icons.auto_stories.codePoint: Icons.auto_stories,
    Icons.history_edu.codePoint: Icons.history_edu,
    Icons.music_note.codePoint: Icons.music_note,
    Icons.movie.codePoint: Icons.movie,
    Icons.edit.codePoint: Icons.edit,
    Icons.forum.codePoint: Icons.forum,
    Icons.book.codePoint: Icons.book,
    
    // Add a fallback icon
    Icons.help_outline.codePoint: Icons.help_outline,
  };
}