import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar la configuración local de la aplicación (Tema, Idioma).
/// Persiste los datos utilizando SharedPreferences.
class SettingsService with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;

  SettingsService() {
    _loadSettings();
  }

  /// Carga las preferencias guardadas al iniciar el servicio.
  Future<void> _loadSettings() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Cargar Tema
      final String? theme = prefs.getString('themeMode');
      if (theme == 'light') {
        _themeMode = ThemeMode.light;
      } else if (theme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }

      // Cargar Idioma
      final String? langCode = prefs.getString('languageCode');
      if (langCode == 'en') {
        _locale = const Locale('en');
      } else if (langCode == 'es') {
        _locale = const Locale('es');
      } else {
        _locale = null; // Usa el idioma del sistema
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando configuración: $e');
      // En caso de error, mantenemos los valores por defecto (System)
    }
  }

  /// Actualiza y persiste el modo del tema (Claro/Oscuro/Sistema).
  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null || newThemeMode == _themeMode) {
      return;
    }

    _themeMode = newThemeMode;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (newThemeMode == ThemeMode.light) {
        await prefs.setString('themeMode', 'light');
      } else if (newThemeMode == ThemeMode.dark) {
        await prefs.setString('themeMode', 'dark');
      } else {
        await prefs.setString('themeMode', 'system');
      }
    } catch (e) {
      debugPrint('Error guardando tema: $e');
    }
  }

  /// Actualiza y persiste el idioma de la aplicación.
  /// Si [newLocale] es null, se usa el idioma del sistema.
  Future<void> updateLocale(Locale? newLocale) async {
    if (newLocale == _locale) {
      return;
    }

    _locale = newLocale;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (newLocale == null) {
        await prefs.remove('languageCode');
      } else {
        await prefs.setString('languageCode', newLocale.languageCode);
      }
    } catch (e) {
      debugPrint('Error guardando idioma: $e');
    }
  }
}
