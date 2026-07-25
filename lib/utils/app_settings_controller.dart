import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ChatBackgroundStyle {
  warm,
  light,
  sage,
  dark,
}

class AppSettingsController extends ChangeNotifier {
  AppSettingsController._();

  static final AppSettingsController instance = AppSettingsController._();

  static const String _themeModeKey = 'app_theme_mode';
  static const String _chatFontSizeKey = 'chat_font_size';
  static const String _chatBackgroundKey = 'chat_background_style';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _profileVisibleKey = 'profile_visible_in_discover';
  static const String _showOnlineStatusKey = 'show_online_status';

  ThemeMode _themeMode = ThemeMode.light;
  double _chatFontSize = 14.5;
  ChatBackgroundStyle _chatBackgroundStyle = ChatBackgroundStyle.warm;
  bool _notificationsEnabled = true;
  bool _profileVisible = true;
  bool _showOnlineStatus = true;
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;
  double get chatFontSize => _chatFontSize;
  ChatBackgroundStyle get chatBackgroundStyle => _chatBackgroundStyle;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get profileVisible => _profileVisible;
  bool get showOnlineStatus => _showOnlineStatus;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    if (_isLoaded) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final themeModeName = prefs.getString(_themeModeKey) ?? ThemeMode.light.name;
    final chatFontSizeValue = prefs.getDouble(_chatFontSizeKey) ?? 14.5;
    final chatBackgroundName =
        prefs.getString(_chatBackgroundKey) ?? ChatBackgroundStyle.warm.name;
    final notificationsEnabled =
        prefs.getBool(_notificationsEnabledKey) ?? true;
    final profileVisible = prefs.getBool(_profileVisibleKey) ?? true;
    final showOnlineStatus = prefs.getBool(_showOnlineStatusKey) ?? true;

    _themeMode = ThemeMode.values.firstWhere(
      (item) => item.name == themeModeName,
      orElse: () => ThemeMode.light,
    );
    _chatFontSize = chatFontSizeValue;
    _chatBackgroundStyle = ChatBackgroundStyle.values.firstWhere(
      (item) => item.name == chatBackgroundName,
      orElse: () => ChatBackgroundStyle.warm,
    );
    _notificationsEnabled = notificationsEnabled;
    _profileVisible = profileVisible;
    _showOnlineStatus = showOnlineStatus;
    _isLoaded = true;
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (_themeMode == value) {
      return;
    }
    _themeMode = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, value.name);
  }

  Future<void> setChatFontSize(double value) async {
    if (_chatFontSize == value) {
      return;
    }
    _chatFontSize = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_chatFontSizeKey, value);
  }

  Future<void> setChatBackgroundStyle(ChatBackgroundStyle value) async {
    if (_chatBackgroundStyle == value) {
      return;
    }
    _chatBackgroundStyle = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chatBackgroundKey, value.name);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (_notificationsEnabled == value) {
      return;
    }
    _notificationsEnabled = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, value);
  }

  Future<void> setProfileVisible(bool value) async {
    if (_profileVisible == value) {
      return;
    }
    _profileVisible = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_profileVisibleKey, value);
  }

  Future<void> setShowOnlineStatus(bool value) async {
    if (_showOnlineStatus == value) {
      return;
    }
    _showOnlineStatus = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showOnlineStatusKey, value);
  }
}
