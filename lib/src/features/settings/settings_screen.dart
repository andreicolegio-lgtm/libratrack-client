import 'package:flutter/material.dart';
import '../../core/services/settings_service.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

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
            onChanged: (bool value) {
              final ThemeMode newMode =
                  value ? ThemeMode.dark : ThemeMode.light;
              context.read<SettingsService>().updateThemeMode(newMode);
            },
            secondary: Icon(
              settingsService.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            activeTrackColor: Theme.of(context).colorScheme.primary,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage,
                style: Theme.of(context).textTheme.titleMedium),
            trailing: DropdownButton<String>(
              value: settingsService.locale?.languageCode,
              dropdownColor: Theme.of(context).colorScheme.surface,
              style: Theme.of(context).textTheme.bodyMedium,
              onChanged: (String? newLanguageCode) {
                Locale? newLocale;
                if (newLanguageCode == null) {
                  newLocale = null;
                } else if (newLanguageCode == 'en') {
                  newLocale = const Locale('en');
                } else if (newLanguageCode == 'es') {
                  newLocale = const Locale('es');
                }
                context.read<SettingsService>().updateLocale(newLocale);
              },
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem(
                  child: Text('Sistema (Por defecto)'),
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
        ],
      ),
    );
  }
}
