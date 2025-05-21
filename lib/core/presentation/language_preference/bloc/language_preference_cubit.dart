import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/presentation/language_preference/enums/language_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'language_preference_state.dart';


class LanguagePreferenceCubit extends Cubit<LanguagePreferenceState> {
  final SharedPreferences prefs;
  
  LanguagePreferenceCubit({required this.prefs}) 
      : super(LanguagePreferenceState(
          mode: _getInitialMode(prefs),
        ));
  
  static LanguageMode _getInitialMode(SharedPreferences prefs) {
    final savedMode = prefs.getInt('language_mode') ?? 0;
    return LanguageMode.values[savedMode];
  }
  
  // Add languageCode getter
  String get languageCode => 
      state.mode == LanguageMode.beginner ? 'en' : 'ko';
  
  Future<void> setLanguageMode(LanguageMode mode) async {
    await prefs.setInt('language_mode', mode.index);
    emit(state.copyWith(mode: mode));
  }
  
  String getLocalizedText({
    required String korean,
    required String english,
    String? mixed,
    List<String>? hardWords,
  }) {
    switch (state.mode) {
      case LanguageMode.beginner:
        return english;
        // return english + (korean.length < 15 ? ' ($korean)' : ''); //TODO: Do something with this
        
      case LanguageMode.intermediate:
        return mixed ?? '$korean ($english)';
        
      case LanguageMode.advanced:
        if (hardWords != null && hardWords.isNotEmpty) {
          String resultText = korean;
          for (String word in hardWords) {
            if (korean.contains(word)) {
              resultText = resultText.replaceAll(word, '$word (${_getEnglishForHardWord(word, english)})');
            }
          }
          return resultText;
        }
        return korean;
        
      case LanguageMode.fullKorean:
        return korean;
    }
  }
  
  String _getEnglishForHardWord(String koreanWord, String englishText) {
    // Check if the word exists in our dictionary
    if (_hardWordsDictionary.containsKey(koreanWord)) {
      return _hardWordsDictionary[koreanWord]!;
    }
    
    // For words not in dictionary, try to find partial matches
    for (var entry in _hardWordsDictionary.entries) {
      if (koreanWord.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // If no match found, fall back to the full English text
    return englishText;
  }
  
  String getAppropriateText({
    required Map<LanguageMode, String> textVariants,
  }) {
    return textVariants[state.mode] ?? textVariants[LanguageMode.intermediate]!;
  }
}

  // Simple dictionary of hard Korean words with translations
  final Map<String, String> _hardWordsDictionary = {
    '읽기 연습': 'Reading Practice',
    '쓰기 연습': 'Writing Practice',
    '듣기 연습': 'Listening Practice',
    '문법': 'Grammar',
    '단어': 'Vocabulary',
    '발음': 'Pronunciation',
    '고급 문법': 'Advanced Grammar',
    '초급 레벨': 'Beginner Level',
    '중급 레벨': 'Intermediate Level',
    '고급 레벨': 'Advanced Level',
    '시험 카테고리': 'Test Categories',
    '진행 상황': 'Progress',
    '완료': 'Complete',
    '계속하기': 'Continue',
    '최근 시험': 'Recent Tests',
    '모두 보기': 'See All',
    '기본 문법 퀴즈': 'Basic Grammar Quiz',
    '테스트': 'Test',
    '연습': 'Practice',
    '점수': 'Score',
    '결과': 'Results',
    '시작하기': 'Start',
    '종료하기': 'End',
    '제출하기': 'Submit',
    '다시 시도': 'Try Again',
    '테스트합니다': 'evaluates',
    '학습을 계속하세요': 'continue your learning'
  };