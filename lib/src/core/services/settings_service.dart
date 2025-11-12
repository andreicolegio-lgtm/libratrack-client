// lib/src/core/services/settings_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio que gestiona los ajustes del usuario (Tema e Idioma).
class SettingsService with ChangeNotifier {
  final SharedPreferences _prefs;
  
  // Claves de guardado
  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'locale';

  // --- Estado ---
  ThemeMode _themeMode = ThemeMode.dark;
  Locale? _locale; // null = idioma del sistema

  SettingsService(this._prefs) {
    _loadTheme();
    _loadLocale();
  }
  
  // --- Getters ---
  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;
  
  // --- Lógica de Tema ---
  void _loadTheme() {
    final String? theme = _prefs.getString(_themeKey);
    if (theme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark; // Default a oscuro
    }
    // No notificar, se carga al inicio
  }

  Future<void> toggleTheme() async {
    _themeMode = (_themeMode == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
    await _prefs.setString(_themeKey, _themeMode == ThemeMode.light ? 'light' : 'dark');
    notifyListeners();
  }
  
  // --- Lógica de Idioma ---
  void _loadLocale() {
    final String? languageCode = _prefs.getString(_localeKey);
    if (languageCode != null) {
      _locale = Locale(languageCode);
    }
    // Si es null, Flutter usará el idioma del sistema
    // No notificar, se carga al inicio
  }
  
  /// Cambia el idioma actual y lo guarda
  Future<void> setLocale(String? languageCode) async {
    if (languageCode == null) {
      _locale = null;
      await _prefs.remove(_localeKey);
    } else {
      _locale = Locale(languageCode);
      await _prefs.setString(_localeKey, languageCode);
    }
    notifyListeners();
  }
}