part of 'language_preference_cubit.dart';

class LanguagePreferenceState extends Equatable {
  final LanguageMode mode;
  
  const LanguagePreferenceState({
    required this.mode,
  });
  
  @override
  List<Object> get props => [mode];
  
  LanguagePreferenceState copyWith({
    LanguageMode? mode,
  }) {
    return LanguagePreferenceState(
      mode: mode ?? this.mode,
    );
  }
}