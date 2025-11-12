// lib/src/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/settings_service.dart';
import 'package:provider/provider.dart';
import 'package:libratrack_client/src/core/l10n/app_localizations.dart';

/// --- ¡ACTUALIZADO (Sprint 9)! ---
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Usamos 'watch' para que la UI se actualice con los cambios
    final settingsService = context.watch<SettingsService>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle, style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // (Petición 10) Interruptor del Modo Oscuro
          SwitchListTile.adaptive(
            title: Text(
              l10n.settingsDarkMode,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              settingsService.themeMode == ThemeMode.dark 
                ? l10n.settingsDarkModeOn
                : l10n.settingsDarkModeOff,
            ),
            value: settingsService.themeMode == ThemeMode.dark,
            onChanged: (value) {
              context.read<SettingsService>().toggleTheme();
            },
            secondary: Icon(
              settingsService.themeMode == ThemeMode.dark 
                ? Icons.dark_mode
                : Icons.light_mode,
            ),
            activeTrackColor: Theme.of(context).colorScheme.primary,
          ),
          
          const Divider(),

          // --- ¡SELECTOR DE IDIOMA! (Petición 11) ---
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage, style: Theme.of(context).textTheme.titleMedium),
            trailing: DropdownButton<String>(
              // El valor actual, o 'null' para "Idioma del Sistema"
              value: settingsService.locale?.languageCode,
              dropdownColor: Theme.of(context).colorScheme.surface,
              style: Theme.of(context).textTheme.bodyMedium,
              onChanged: (String? newLanguageCode) {
                // Usamos 'read' en el callback
                context.read<SettingsService>().setLocale(newLanguageCode);
              },
              items: [
                // 1. Opción "Idioma del Sistema"
                const DropdownMenuItem(
                  value: null,
                  child: Text('Sistema (Por defecto)'),
                ),
                // 2. Opciones de nuestros archivos .arb
                DropdownMenuItem(
                  value: 'es',
                  child: Text(l10n.settingsLanguageSpanish),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(l10n.settingsLanguageEnglish),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}