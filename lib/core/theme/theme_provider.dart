import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  static const String _key = 'theme_mode';

  final SharedPreferences _prefs;
  ThemeMode _themeMode;

  ThemeNotifier(this._prefs)
      : _themeMode = _loadFromPrefs(_prefs);

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  static ThemeMode _loadFromPrefs(SharedPreferences prefs) {
    final value = prefs.getString(_key);
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    _prefs.setString(_key, mode.name);
    notifyListeners();
  }

  void toggleTheme() {
    setTheme(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
