// lib/providers/settings_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyDarkMode  = 'dark_mode';
  static const _keyFontScale = 'font_scale';

  bool   _darkMode  = false;
  double _fontScale = 1.0;   // 0.8 = small, 1.0 = normal, 1.3 = large

  bool   get darkMode  => _darkMode;
  double get fontScale => _fontScale;

  ThemeMode get themeMode => _darkMode ? ThemeMode.dark : ThemeMode.light;

  // Call once at startup
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode  = prefs.getBool(_keyDarkMode)   ?? false;
    _fontScale = prefs.getDouble(_keyFontScale) ?? 1.0;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  Future<void> setFontScale(double value) async {
    _fontScale = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontScale, value);
  }
}