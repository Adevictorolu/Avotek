import 'package:flutter/material.dart';
import '../core/database/app_database.dart';

/// Global Theme Provider ensuring light and dark themes stay in 100% sync
/// across all screens, dialogs, drawers, and responsive layouts.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider() {
    _initTheme();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void _initTheme() {
    final saved = AppDatabaseService.instance.getThemeMode();
    if (saved == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    AppDatabaseService.instance.saveThemeMode(_themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      AppDatabaseService.instance.saveThemeMode(mode == ThemeMode.dark ? 'dark' : 'light');
      notifyListeners();
    }
  }
}
