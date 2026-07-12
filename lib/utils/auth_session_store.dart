import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionStore {
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userJsonKey = 'auth_user_json';

  static String accessToken = '';
  static String refreshToken = '';
  static Map<String, dynamic> user = <String, dynamic>{};

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString(_accessTokenKey) ?? '';
    refreshToken = prefs.getString(_refreshTokenKey) ?? '';
    final userJson = prefs.getString(_userJsonKey);
    if (userJson == null || userJson.isEmpty) {
      user = <String, dynamic>{};
      return;
    }
    user = Map<String, dynamic>.from(jsonDecode(userJson) as Map);
  }

  static Future<void> saveSession({
    required String accessTokenValue,
    required String refreshTokenValue,
    required Map<String, dynamic> userValue,
  }) async {
    accessToken = accessTokenValue;
    refreshToken = refreshTokenValue;
    user = Map<String, dynamic>.from(userValue);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_userJsonKey, jsonEncode(user));
  }

  static Future<void> saveUser(Map<String, dynamic> userValue) async {
    user = Map<String, dynamic>.from(userValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userJsonKey, jsonEncode(user));
  }

  static Future<void> clear() async {
    accessToken = '';
    refreshToken = '';
    user = <String, dynamic>{};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userJsonKey);
  }
}
