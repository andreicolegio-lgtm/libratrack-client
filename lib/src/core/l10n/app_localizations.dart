import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// El título principal de la aplicación
  ///
  /// In es, this message translates to:
  /// **'LibraTrack'**
  String get appTitle;

  /// Texto del botón en la pantalla de login
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get loginButton;

  /// Etiqueta para el campo de texto de email
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// Etiqueta para el campo de texto de contraseña
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get loginPasswordLabel;

  /// Error de validación para email vacío
  ///
  /// In es, this message translates to:
  /// **'El email es obligatorio.'**
  String get loginEmailRequired;

  /// Error de validación para email con formato incorrecto
  ///
  /// In es, this message translates to:
  /// **'Introduce un email válido.'**
  String get loginEmailInvalid;

  /// Error de validación para contraseña vacía
  ///
  /// In es, this message translates to:
  /// **'La contraseña es obligatoria.'**
  String get loginPasswordRequired;

  /// Texto del botón para ir a la pantalla de registro
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Regístrate'**
  String get loginRegisterPrompt;

  /// Texto del botón en la pantalla de registro
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get registerTitle;

  /// Etiqueta para el campo de texto de nombre de usuario
  ///
  /// In es, this message translates to:
  /// **'Nombre de Usuario'**
  String get registerUsernameLabel;

  /// Error de validación para nombre de usuario vacío
  ///
  /// In es, this message translates to:
  /// **'El nombre de usuario es obligatorio.'**
  String get registerUsernameRequired;

  /// Error de validación para nombre de usuario corto
  ///
  /// In es, this message translates to:
  /// **'Debe tener al menos 4 caracteres.'**
  String get registerUsernameLength;

  /// Error de validación para contraseña corta
  ///
  /// In es, this message translates to:
  /// **'Debe tener al menos 8 caracteres.'**
  String get registerPasswordLength;

  /// Texto del botón para volver a la pantalla de login
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Inicia sesión'**
  String get registerLoginPrompt;

  /// Texto para la barra de navegación - Catálogo
  ///
  /// In es, this message translates to:
  /// **'Catálogo'**
  String get bottomNavCatalog;

  /// Texto para la barra de navegación - Buscar
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get bottomNavSearch;

  /// Texto para la barra de navegación - Perfil
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get bottomNavProfile;

  /// Título de la pantalla de Catálogo
  ///
  /// In es, this message translates to:
  /// **'Mi Catálogo'**
  String get catalogTitle;

  /// Pestaña del catálogo - En Progreso
  ///
  /// In es, this message translates to:
  /// **'En Progreso'**
  String get catalogInProgress;

  /// Pestaña del catálogo - Pendiente
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get catalogPending;

  /// Pestaña del catálogo - Terminado
  ///
  /// In es, this message translates to:
  /// **'Terminado'**
  String get catalogFinished;

  /// Pestaña del catálogo - Abandonado
  ///
  /// In es, this message translates to:
  /// **'Abandonado'**
  String get catalogDropped;

  /// Texto que aparece si una pestaña del catálogo está vacía
  ///
  /// In es, this message translates to:
  /// **'No hay elementos en estado: {estado}'**
  String catalogEmptyState(String estado);

  /// Subtítulo en la pantalla de búsqueda
  ///
  /// In es, this message translates to:
  /// **'Explorar por Tipo'**
  String get searchExploreType;

  /// Subtítulo en la pantalla de búsqueda
  ///
  /// In es, this message translates to:
  /// **'Explorar por Género'**
  String get searchExploreGenre;

  /// Texto de ayuda en la barra de búsqueda
  ///
  /// In es, this message translates to:
  /// **'Buscar por título...'**
  String get searchFieldHint;

  /// Texto si la búsqueda no devuelve resultados
  ///
  /// In es, this message translates to:
  /// **'No se encontraron elementos con el filtro aplicado.'**
  String get searchEmptyState;

  /// Texto del botón flotante para proponer un elemento
  ///
  /// In es, this message translates to:
  /// **'Proponer Elemento'**
  String get searchProposeButton;

  /// Subtítulo para la sección de datos de usuario
  ///
  /// In es, this message translates to:
  /// **'Datos de Usuario'**
  String get profileUserData;

  /// Texto del botón para guardar cambios del perfil
  ///
  /// In es, this message translates to:
  /// **'Guardar Cambios'**
  String get profileSaveButton;

  /// Subtítulo para la sección de cambio de contraseña
  ///
  /// In es, this message translates to:
  /// **'Cambiar Contraseña'**
  String get profileChangePassword;

  /// Etiqueta para el campo de contraseña actual
  ///
  /// In es, this message translates to:
  /// **'Contraseña actual'**
  String get profileCurrentPassword;

  /// Etiqueta para el campo de nueva contraseña
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get profileNewPassword;

  /// Texto del botón para ir al panel de moderación
  ///
  /// In es, this message translates to:
  /// **'Panel de Moderación'**
  String get profileModPanelButton;

  /// Texto del botón para ir al panel de administrador
  ///
  /// In es, this message translates to:
  /// **'Panel de Administrador'**
  String get profileAdminPanelButton;

  /// Texto del botón para cerrar sesión
  ///
  /// In es, this message translates to:
  /// **'Cerrar Sesión'**
  String get profileLogoutButton;

  /// Título de la pantalla de Ajustes
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// Etiqueta para el interruptor de modo oscuro
  ///
  /// In es, this message translates to:
  /// **'Modo Oscuro'**
  String get settingsDarkMode;

  /// Subtítulo del interruptor de modo oscuro (Activado)
  ///
  /// In es, this message translates to:
  /// **'Activado'**
  String get settingsDarkModeOn;

  /// Subtítulo del interruptor de modo oscuro (Desactivado)
  ///
  /// In es, this message translates to:
  /// **'Desactivado'**
  String get settingsDarkModeOff;

  /// Etiqueta para la selección de idioma
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// Opción de idioma Español
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get settingsLanguageSpanish;

  /// Opción de idioma Inglés
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get settingsLanguageEnglish;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
