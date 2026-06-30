import 'package:shared_preferences/shared_preferences.dart';

class StorageManager {
  static SharedPreferences? _prefs;

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Auth Token
  static String? getToken() {
    return _prefs?.getString(_tokenKey);
  }

  static Future<bool> setToken(String token) async {
    await init();
    return await _prefs?.setString(_tokenKey, token) ?? false;
  }

  static Future<bool> removeToken() async {
    await init();
    return await _prefs?.remove(_tokenKey) ?? false;
  }

  // User details
  static String? getUserJson() {
    return _prefs?.getString(_userKey);
  }

  static Future<bool> setUserJson(String jsonStr) async {
    await init();
    return await _prefs?.setString(_userKey, jsonStr) ?? false;
  }

  static Future<bool> removeUserJson() async {
    await init();
    return await _prefs?.remove(_userKey) ?? false;
  }

  // Clear all
  static Future<void> clearAll() async {
    await init();
    await _prefs?.clear();
  }
}
