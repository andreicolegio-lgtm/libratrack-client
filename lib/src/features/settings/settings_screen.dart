import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/settings_service.dart';
import '../../core/l10n/app_localizations.dart';

/// Pantalla para configurar preferencias globales de la aplicación.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    // Usamos watch para reconstruir la UI cuando cambien los settings
    final SettingsService settingsService = context.watch<SettingsService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle,
            style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          // Sección: Apariencia
          _buildSectionHeader(context, 'Apariencia'), // Podría ir a l10n
          SwitchListTile.adaptive(
            title: Text(l10n.settingsDarkMode,
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(
              settingsService.themeMode == ThemeMode.dark
                  ? l10n.settingsDarkModeOn
                  : l10n.settingsDarkModeOff,
            ),
            value: settingsService.themeMode == ThemeMode.dark,
            onChanged: (bool value) {
              final ThemeMode newMode =
                  value ? ThemeMode.dark : ThemeMode.light;
              context.read<SettingsService>().updateThemeMode(newMode);
            },
            secondary: Icon(
              settingsService.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            contentPadding: EdgeInsets.zero,
          ),

          const Divider(),

          // Sección: Idioma
          _buildSectionHeader(context, 'Idioma'), // Podría ir a l10n
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage,
                style: Theme.of(context).textTheme.titleMedium),
            trailing: DropdownButton<String>(
              value: settingsService.locale?.languageCode ?? 'system',
              underline: Container(), // Ocultar línea fea
              dropdownColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              style: Theme.of(context).textTheme.bodyMedium,
              onChanged: (String? newLanguageCode) {
                Locale? newLocale;
                if (newLanguageCode == 'system') {
                  newLocale = null;
                } else if (newLanguageCode != null) {
                  newLocale = Locale(newLanguageCode);
                }
                context.read<SettingsService>().updateLocale(newLocale);
              },
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem(
                  value: 'system',
                  child: Text(l10n.settingsSystemDefault),
                ),
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

          const Divider(),

          // Información de la App (Opcional)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline),
            title: const Text('Versión'),
            trailing:
                Text('1.0.0', style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
