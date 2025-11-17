import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;

  SettingsService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? theme = prefs.getString('themeMode');
    if (theme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    final String? langCode = prefs.getString('languageCode');
    if (langCode == 'en') {
      _locale = const Locale('en');
    } else if (langCode == 'es') {
      _locale = const Locale('es');
    } else {
      _locale = null;
    }

    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null || newThemeMode == _themeMode) {
      return;
    }

    _themeMode = newThemeMode;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (newThemeMode == ThemeMode.light) {
      await prefs.setString('themeMode', 'light');
    } else if (newThemeMode == ThemeMode.dark) {
      await prefs.setString('themeMode', 'dark');
    } else {
      await prefs.setString('themeMode', 'system');
    }
  }

  Future<void> updateLocale(Locale? newLocale) async {
    if (newLocale == _locale) {
      return;
    }

    debugPrint('[SettingsService] Locale updated to: '
        '${newLocale?.languageCode ?? 'system default'}');

    _locale = newLocale;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (newLocale == null) {
      await prefs.remove('languageCode');
    } else {
      await prefs.setString('languageCode', newLocale.languageCode);
    }
  }
}
