enum LanguageMode {
  beginner,
  intermediate,
  advanced,
  fullKorean,
}

extension LanguageModeExtension on LanguageMode {
  String get label {
    switch (this) {
      case LanguageMode.beginner:
        return 'Beginner';
      case LanguageMode.intermediate:
        return 'Intermediate';
      case LanguageMode.advanced:
        return 'Advanced';
      case LanguageMode.fullKorean:
        return 'Full Korean';
    }
  }
}