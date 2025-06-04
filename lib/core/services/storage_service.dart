import 'package:shared_preferences/shared_preferences.dart';

abstract class StorageService {
  Future<void> setString(String key, String value);
  Future<void> setInt(String key, int value);
  Future<void> setBool(String key, bool value);
  
  String? getString(String key);
  int? getInt(String key);
  bool? getBool(String key);
  
  Future<void> remove(String key);
  Future<void> clear();
  bool containsKey(String key);
  Set<String> getAllKeys(); // Added this method
}

class SharedPreferencesStorageService implements StorageService {
  final SharedPreferences _prefs;
  
  SharedPreferencesStorageService(this._prefs);
  
  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }
  
  @override
  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }
  
  @override
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }
  
  @override
  String? getString(String key) {
    return _prefs.getString(key);
  }
  
  @override
  int? getInt(String key) {
    return _prefs.getInt(key);
  }
  
  @override
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }
  
  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
  
  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
  
  @override
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
  
  @override
  Set<String> getAllKeys() {
    return _prefs.getKeys();
  }
}