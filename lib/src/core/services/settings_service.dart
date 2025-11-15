// Archivo: lib/src/core/services/settings_service.dart
// (¡REFACTORIZADO!)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:libratrack_client/src/core/l10n/app_localizations.dart'; // <-- Importación no utilizada

class SettingsService with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;

  // --- ¡CONSTRUCTOR MODIFICADO! ---
  // Se elimina la dependencia 'onLanguageChanged'.
  // El 'Consumer' en main.dart ya maneja la actualización de la UI.
  SettingsService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Cargar Tema
    final theme = prefs.getString('themeMode');
    if (theme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    // Cargar Idioma
    final langCode = prefs.getString('languageCode');
    if (langCode == 'en') {
      _locale = const Locale('en');
    } else if (langCode == 'es') {
      _locale = const Locale('es');
    } else {
      _locale = null; // Sistema (Por defecto)
    }
    
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null || newThemeMode == _themeMode) return;

    _themeMode = newThemeMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (newThemeMode == ThemeMode.light) {
      await prefs.setString('themeMode', 'light');
    } else if (newThemeMode == ThemeMode.dark) {
      await prefs.setString('themeMode', 'dark');
    } else {
      await prefs.setString('themeMode', 'system');
    }
  }

  Future<void> updateLocale(Locale? newLocale) async {
    if (newLocale == _locale) return;

    _locale = newLocale;
    // ¡Ya no se llama al callback! El 'notifyListeners' es suficiente.
    notifyListeners(); 

    final prefs = await SharedPreferences.getInstance();
    if (newLocale == null) {
      await prefs.remove('languageCode'); // 'Sistema' es la ausencia de la clave
    } else {
      await prefs.setString('languageCode', newLocale.languageCode);
    }
  }
}