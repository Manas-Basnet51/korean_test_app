import 'package:flutter/material.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';

enum BookLevel {
  beginner,
  intermediate,
  advanced,
  expert
}

extension BookLevelExtension on BookLevel {
  String getName(LanguagePreferenceCubit languageCubit) {
    switch (this) {
      case BookLevel.beginner:
        return languageCubit.getLocalizedText(
          korean: '초급',
          english: 'Beginner',
        );
      case BookLevel.intermediate:
        return languageCubit.getLocalizedText(
          korean: '중급',
          english: 'Intermediate',
        );
      case BookLevel.advanced:
        return languageCubit.getLocalizedText(
          korean: '고급',
          english: 'Advanced',
        );
      case BookLevel.expert:
        return languageCubit.getLocalizedText(
          korean: '고급',//TODO: change
          english: 'Expert',
        );
    }
  }
  
  Color getColor() {
    switch (this) {
      case BookLevel.beginner:
        return Colors.green;
      case BookLevel.intermediate:
        return Colors.blue;
      case BookLevel.advanced:
        return Colors.purple;
      case BookLevel.expert:
        return Colors.deepOrange;
    }
  }
}