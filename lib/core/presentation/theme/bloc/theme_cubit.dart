import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme Cubit for managing theme state
class ThemeCubit extends Cubit<ThemeMode> {
  static const String _themeKey = 'app_theme';
  final SharedPreferences _prefs;

  ThemeCubit(this._prefs) : super(_getThemeFromPrefs(_prefs));

  static ThemeMode _getThemeFromPrefs(SharedPreferences prefs) {
    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex == null) return ThemeMode.system;
    return ThemeMode.values[themeIndex];
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    await _prefs.setInt(_themeKey, themeMode.index);
    emit(themeMode);
  }

  void setLightTheme() => setTheme(ThemeMode.light);
  void setDarkTheme() => setTheme(ThemeMode.dark);
  void setSystemTheme() => setTheme(ThemeMode.system);
}