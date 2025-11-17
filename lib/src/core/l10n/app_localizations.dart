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

  /// No description provided for @loginTitle.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a LibraTrack'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para continuar'**
  String get loginSubtitle;

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

  /// No description provided for @loginOr.
  ///
  /// In es, this message translates to:
  /// **'O'**
  String get loginOr;

  /// No description provided for @loginGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get loginGoogle;

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

  /// No description provided for @settingsSystemDefault.
  ///
  /// In es, this message translates to:
  /// **'Sistema (Por defecto)'**
  String get settingsSystemDefault;

  /// Error de validación para nombre de usuario vacío
  ///
  /// In es, this message translates to:
  /// **'El nombre de usuario es obligatorio.'**
  String get validationUsernameRequired;

  /// Error de validación para longitud de nombre de usuario
  ///
  /// In es, this message translates to:
  /// **'El nombre de usuario debe tener entre 4 y 50 caracteres.'**
  String get validationUsernameLength450;

  /// Error de validación para email vacío
  ///
  /// In es, this message translates to:
  /// **'El email es obligatorio.'**
  String get validationEmailRequired;

  /// Error de validación para email con formato incorrecto
  ///
  /// In es, this message translates to:
  /// **'Introduce un email válido.'**
  String get validationEmailInvalid;

  /// Error de validación para contraseña vacía
  ///
  /// In es, this message translates to:
  /// **'La contraseña es obligatoria.'**
  String get validationPasswordRequired;

  /// Error de validación para contraseña actual vacía
  ///
  /// In es, this message translates to:
  /// **'La contraseña actual es obligatoria.'**
  String get validationPasswordCurrentRequired;

  /// Error de validación para nueva contraseña vacía
  ///
  /// In es, this message translates to:
  /// **'La nueva contraseña es obligatoria.'**
  String get validationPasswordNewRequired;

  /// Error de validación para contraseña corta
  ///
  /// In es, this message translates to:
  /// **'La nueva contraseña debe tener al menos 8 caracteres.'**
  String get validationPasswordMin8;

  /// Error de validación
  ///
  /// In es, this message translates to:
  /// **'El ID del elemento no puede ser nulo.'**
  String get validationElementIdRequired;

  /// Error de validación
  ///
  /// In es, this message translates to:
  /// **'La valoración es obligatoria.'**
  String get validationRatingRequired;

  /// Error de validación
  ///
  /// In es, this message translates to:
  /// **'La valoración mínima es 1.'**
  String get validationRatingMin1;

  /// Error de validación
  ///
  /// In es, this message translates to:
  /// **'La valoración máxima es 5.'**
  String get validationRatingMax5;

  /// Error de validación
  ///
  /// In es, this message translates to:
  /// **'La reseña no puede exceder los 2000 caracteres.'**
  String get validationReviewMax2000;

  /// Error de validación
  ///
  /// In es, this message translates to:
  /// **'El título es obligatorio.'**
  String get validationTitleRequired;

  /// Error de validación
  ///
  /// In es, this message translates to:
  /// **'La descripción es obligatoria.'**
  String get validationDescRequired;

  /// Error de validación
  ///
  /// In es, this message translates to:
  /// **'El tipo es obligatorio.'**
  String get validationTypeRequired;

  /// Error de validación
  ///
  /// In es, this message translates to:
  /// **'Los géneros son obligatorios.'**
  String get validationGenresRequired;

  /// Error de validación
  ///
  /// In es, this message translates to:
  /// **'El token de Google no puede estar vacío.'**
  String get validationGoogleTokenRequired;

  /// Error de validación
  ///
  /// In es, this message translates to:
  /// **'Debe especificar el estado de moderador.'**
  String get validationModStatusRequired;

  /// Error de validación
  ///
  /// In es, this message translates to:
  /// **'Debe especificar el estado de administrador.'**
  String get validationAdminStatusRequired;

  /// Error: El email ya está registrado.
  ///
  /// In es, this message translates to:
  /// **'El email ya está registrado.'**
  String get errorEmailAlreadyRegistered;

  /// Error: El nombre de usuario ya existe.
  ///
  /// In es, this message translates to:
  /// **'El nombre de usuario ya existe.'**
  String get errorUsernameAlreadyExists;

  /// Error: La contraseña actual es incorrecta.
  ///
  /// In es, this message translates to:
  /// **'La contraseña actual es incorrecta.'**
  String get errorPasswordIncorrect;

  /// Error: Ya has reseñado este elemento.
  ///
  /// In es, this message translates to:
  /// **'Ya has reseñado este elemento.'**
  String get errorAlreadyReviewed;

  /// Error: La valoración debe estar entre 1 y 5.
  ///
  /// In es, this message translates to:
  /// **'La valoración debe estar entre 1 y 5.'**
  String get errorInvalidRatingRange;

  /// Error: Propuesta ya gestionada.
  ///
  /// In es, this message translates to:
  /// **'Esta propuesta ya ha sido gestionada.'**
  String get errorProposalAlreadyHandled;

  /// Error: Tipo vacío.
  ///
  /// In es, this message translates to:
  /// **'El Tipo sugerido no puede estar vacío.'**
  String get errorTypeEmpty;

  /// Error: Géneros vacíos.
  ///
  /// In es, this message translates to:
  /// **'Los Géneros sugeridos no pueden estar vacíos.'**
  String get errorGenresEmpty;

  /// Error: Género inválido.
  ///
  /// In es, this message translates to:
  /// **'Se debe proporcionar al menos un género válido.'**
  String get errorGenreInvalid;

  /// Error: Archivo vacío.
  ///
  /// In es, this message translates to:
  /// **'El archivo está vacío.'**
  String get errorFileEmpty;

  /// Error: Ya está en el catálogo.
  ///
  /// In es, this message translates to:
  /// **'Este elemento ya está en tu catálogo.'**
  String get errorAlreadyInCatalog;

  /// Error: Error de validación.
  ///
  /// In es, this message translates to:
  /// **'Error de validación.'**
  String get errorValidation;

  /// Error: Argumento no válido.
  ///
  /// In es, this message translates to:
  /// **'Argumento no válido.'**
  String get errorIllegalArgument;

  /// Error: Error interno del servidor.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error inesperado. Por favor, inténtalo de nuevo más tarde.'**
  String get errorInternalServerError;

  /// Error: Acceso denegado.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para acceder a este recurso.'**
  String get errorAccessDenied;

  /// Error: Token JWT caducado.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión ha caducado. Por favor, inicia sesión de nuevo.'**
  String get errorTokenExpired;

  /// Error: Token JWT inválido.
  ///
  /// In es, this message translates to:
  /// **'Token inválido. Por favor, inicia sesión de nuevo.'**
  String get errorTokenInvalid;

  /// Error: Credenciales de login inválidas.
  ///
  /// In es, this message translates to:
  /// **'Email o contraseña incorrectos.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorUnexpected.
  ///
  /// In es, this message translates to:
  /// **'Error inesperado: {error}'**
  String errorUnexpected(String error);

  /// No description provided for @errorLoadingFilters.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar filtros: {error}'**
  String errorLoadingFilters(String error);

  /// No description provided for @errorLoadingElement.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar el elemento:\n{error}'**
  String errorLoadingElement(String error);

  /// No description provided for @errorLoadingElements.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar elementos: {error}'**
  String errorLoadingElements(String error);

  /// No description provided for @errorLoadingReviews.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar las reseñas: {error}'**
  String errorLoadingReviews(String error);

  /// No description provided for @errorLoadingProposals.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar:\n{error}'**
  String errorLoadingProposals(String error);

  /// No description provided for @errorLoadingUsers.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String errorLoadingUsers(String error);

  /// No description provided for @errorLoadingCatalog.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String errorLoadingCatalog(String error);

  /// No description provided for @errorImagePick.
  ///
  /// In es, this message translates to:
  /// **'Error al seleccionar imagen: {error}'**
  String errorImagePick(String error);

  /// No description provided for @errorImageUpload.
  ///
  /// In es, this message translates to:
  /// **'Error al subir imagen: {error}'**
  String errorImageUpload(String error);

  /// No description provided for @errorSaving.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar: {error}'**
  String errorSaving(String error);

  /// No description provided for @errorUpdating.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar: {error}'**
  String errorUpdating(String error);

  /// No description provided for @errorApproving.
  ///
  /// In es, this message translates to:
  /// **'Error al aprobar: {error}'**
  String errorApproving(String error);

  /// No description provided for @errorUpdatingRoles.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar roles: {error}'**
  String errorUpdatingRoles(String error);

  /// No description provided for @snackbarCloseButton.
  ///
  /// In es, this message translates to:
  /// **'CERRAR'**
  String get snackbarCloseButton;

  /// No description provided for @snackbarLoginGoogleCancel.
  ///
  /// In es, this message translates to:
  /// **'Inicio de sesión cancelado.'**
  String get snackbarLoginGoogleCancel;

  /// No description provided for @snackbarRegisterSuccess.
  ///
  /// In es, this message translates to:
  /// **'¡Registro exitoso! Por favor, inicia sesión.'**
  String get snackbarRegisterSuccess;

  /// No description provided for @snackbarReviewPublished.
  ///
  /// In es, this message translates to:
  /// **'¡Reseña publicada!'**
  String get snackbarReviewPublished;

  /// No description provided for @snackbarReviewRatingRequired.
  ///
  /// In es, this message translates to:
  /// **'Por favor, selecciona una valoración (1-5 estrellas).'**
  String get snackbarReviewRatingRequired;

  /// No description provided for @snackbarProposalSent.
  ///
  /// In es, this message translates to:
  /// **'¡Propuesta enviada con éxito! Gracias por tu contribución.'**
  String get snackbarProposalSent;

  /// No description provided for @snackbarProfilePhotoUpdated.
  ///
  /// In es, this message translates to:
  /// **'¡Foto de perfil actualizada!'**
  String get snackbarProfilePhotoUpdated;

  /// No description provided for @snackbarProfileNoChanges.
  ///
  /// In es, this message translates to:
  /// **'No has realizado ningún cambio.'**
  String get snackbarProfileNoChanges;

  /// No description provided for @snackbarProfileUsernameUpdated.
  ///
  /// In es, this message translates to:
  /// **'¡Nombre de usuario actualizado!'**
  String get snackbarProfileUsernameUpdated;

  /// No description provided for @snackbarProfilePasswordUpdated.
  ///
  /// In es, this message translates to:
  /// **'¡Contraseña actualizada con éxito!'**
  String get snackbarProfilePasswordUpdated;

  /// No description provided for @snackbarCatalogAdded.
  ///
  /// In es, this message translates to:
  /// **'¡Añadido al catálogo!'**
  String get snackbarCatalogAdded;

  /// No description provided for @snackbarCatalogRemoved.
  ///
  /// In es, this message translates to:
  /// **'Elemento quitado del catálogo'**
  String get snackbarCatalogRemoved;

  /// No description provided for @snackbarCatalogStatusUpdated.
  ///
  /// In es, this message translates to:
  /// **'Estado actualizado.'**
  String get snackbarCatalogStatusUpdated;

  /// No description provided for @snackbarCatalogProgressSaved.
  ///
  /// In es, this message translates to:
  /// **'Progreso guardado.'**
  String get snackbarCatalogProgressSaved;

  /// No description provided for @snackbarImageUploadSuccess.
  ///
  /// In es, this message translates to:
  /// **'¡Imagen subida!'**
  String get snackbarImageUploadSuccess;

  /// No description provided for @snackbarImageUploadRequired.
  ///
  /// In es, this message translates to:
  /// **'Por favor, sube una imagen de portada.'**
  String get snackbarImageUploadRequired;

  /// No description provided for @snackbarImageUploadRequiredApproval.
  ///
  /// In es, this message translates to:
  /// **'Por favor, sube una imagen de portada antes de aprobar.'**
  String get snackbarImageUploadRequiredApproval;

  /// No description provided for @snackbarModProposalApproved.
  ///
  /// In es, this message translates to:
  /// **'¡Propuesta aprobada!'**
  String get snackbarModProposalApproved;

  /// No description provided for @snackbarModProposalRejected.
  ///
  /// In es, this message translates to:
  /// **'Propuesta rechazada (simulado).'**
  String get snackbarModProposalRejected;

  /// No description provided for @snackbarAdminRolesUpdated.
  ///
  /// In es, this message translates to:
  /// **'Roles de {username} actualizados.'**
  String snackbarAdminRolesUpdated(String username);

  /// No description provided for @snackbarAdminElementUpdated.
  ///
  /// In es, this message translates to:
  /// **'¡Elemento actualizado!'**
  String get snackbarAdminElementUpdated;

  /// No description provided for @snackbarAdminElementCreated.
  ///
  /// In es, this message translates to:
  /// **'¡Elemento OFICIAL creado!'**
  String get snackbarAdminElementCreated;

  /// No description provided for @snackbarAdminStatusCommunity.
  ///
  /// In es, this message translates to:
  /// **'Elemento marcado como COMUNITARIO.'**
  String get snackbarAdminStatusCommunity;

  /// No description provided for @snackbarAdminStatusOfficial.
  ///
  /// In es, this message translates to:
  /// **'¡Elemento marcado como OFICIAL!'**
  String get snackbarAdminStatusOfficial;

  /// No description provided for @reviewModalTitle.
  ///
  /// In es, this message translates to:
  /// **'Escribir Reseña'**
  String get reviewModalTitle;

  /// No description provided for @reviewModalReviewLabel.
  ///
  /// In es, this message translates to:
  /// **'Reseña (opcional)'**
  String get reviewModalReviewLabel;

  /// No description provided for @reviewModalReviewHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu opinión...'**
  String get reviewModalReviewHint;

  /// No description provided for @reviewModalSubmitButton.
  ///
  /// In es, this message translates to:
  /// **'Publicar Reseña'**
  String get reviewModalSubmitButton;

  /// No description provided for @proposalFormTitle.
  ///
  /// In es, this message translates to:
  /// **'Proponer Elemento'**
  String get proposalFormTitle;

  /// No description provided for @proposalFormTitleLabel.
  ///
  /// In es, this message translates to:
  /// **'Título Sugerido'**
  String get proposalFormTitleLabel;

  /// No description provided for @proposalFormDescLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción Breve'**
  String get proposalFormDescLabel;

  /// No description provided for @proposalFormTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo (Ej. Serie, Libro, Anime)'**
  String get proposalFormTypeLabel;

  /// No description provided for @proposalFormGenresLabel.
  ///
  /// In es, this message translates to:
  /// **'Géneros (separados por coma)'**
  String get proposalFormGenresLabel;

  /// No description provided for @proposalFormProgressTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos de Progreso (Opcional)'**
  String get proposalFormProgressTitle;

  /// No description provided for @proposalFormSeriesEpisodesLabel.
  ///
  /// In es, this message translates to:
  /// **'Episodios por Temporada'**
  String get proposalFormSeriesEpisodesLabel;

  /// No description provided for @proposalFormSeriesEpisodesHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. 10,8,12 (para T1, T2, T3)'**
  String get proposalFormSeriesEpisodesHint;

  /// No description provided for @proposalFormBookChaptersLabel.
  ///
  /// In es, this message translates to:
  /// **'Total Capítulos (Libro)'**
  String get proposalFormBookChaptersLabel;

  /// No description provided for @proposalFormBookPagesLabel.
  ///
  /// In es, this message translates to:
  /// **'Total Páginas (Libro)'**
  String get proposalFormBookPagesLabel;

  /// No description provided for @proposalFormAnimeEpisodesLabel.
  ///
  /// In es, this message translates to:
  /// **'Total Episodios (Anime)'**
  String get proposalFormAnimeEpisodesLabel;

  /// No description provided for @proposalFormMangaChaptersLabel.
  ///
  /// In es, this message translates to:
  /// **'Total Capítulos (Manga)'**
  String get proposalFormMangaChaptersLabel;

  /// No description provided for @proposalFormNoProgress.
  ///
  /// In es, this message translates to:
  /// **'El tipo \"{tipo}\" no requiere datos de progreso.'**
  String proposalFormNoProgress(String tipo);

  /// No description provided for @proposalFormSubmitButton.
  ///
  /// In es, this message translates to:
  /// **'Enviar Propuesta'**
  String get proposalFormSubmitButton;

  /// No description provided for @elementDetailSynopsis.
  ///
  /// In es, this message translates to:
  /// **'Sinopsis'**
  String get elementDetailSynopsis;

  /// No description provided for @elementDetailProgressDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalles del Progreso'**
  String get elementDetailProgressDetails;

  /// No description provided for @elementDetailSeriesSeasons.
  ///
  /// In es, this message translates to:
  /// **'Total Temporadas'**
  String get elementDetailSeriesSeasons;

  /// No description provided for @elementDetailSeriesEpisodes.
  ///
  /// In es, this message translates to:
  /// **'Episodios'**
  String get elementDetailSeriesEpisodes;

  /// No description provided for @elementDetailBookChapters.
  ///
  /// In es, this message translates to:
  /// **'Total Capítulos'**
  String get elementDetailBookChapters;

  /// No description provided for @elementDetailBookPages.
  ///
  /// In es, this message translates to:
  /// **'Total Páginas'**
  String get elementDetailBookPages;

  /// No description provided for @elementDetailAnimeEpisodes.
  ///
  /// In es, this message translates to:
  /// **'Total Episodios'**
  String get elementDetailAnimeEpisodes;

  /// No description provided for @elementDetailMangaChapters.
  ///
  /// In es, this message translates to:
  /// **'Total Capítulos'**
  String get elementDetailMangaChapters;

  /// No description provided for @elementDetailPrequels.
  ///
  /// In es, this message translates to:
  /// **'Precuelas'**
  String get elementDetailPrequels;

  /// No description provided for @elementDetailSequels.
  ///
  /// In es, this message translates to:
  /// **'Secuelas'**
  String get elementDetailSequels;

  /// No description provided for @elementDetailReviews.
  ///
  /// In es, this message translates to:
  /// **'Reseñas ({count})'**
  String elementDetailReviews(int count);

  /// No description provided for @elementDetailAlreadyReviewed.
  ///
  /// In es, this message translates to:
  /// **'Ya has reseñado'**
  String get elementDetailAlreadyReviewed;

  /// No description provided for @elementDetailWriteReview.
  ///
  /// In es, this message translates to:
  /// **'Escribir Reseña'**
  String get elementDetailWriteReview;

  /// No description provided for @elementDetailNoReviews.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay reseñas para este elemento.'**
  String get elementDetailNoReviews;

  /// No description provided for @elementDetailAddButton.
  ///
  /// In es, this message translates to:
  /// **'Añadir a Mi Catálogo'**
  String get elementDetailAddButton;

  /// No description provided for @elementDetailAddingButton.
  ///
  /// In es, this message translates to:
  /// **'Añadiendo...'**
  String get elementDetailAddingButton;

  /// No description provided for @elementDetailRemoveButton.
  ///
  /// In es, this message translates to:
  /// **'Quitar del catálogo'**
  String get elementDetailRemoveButton;

  /// No description provided for @elementDetailRemovingButton.
  ///
  /// In es, this message translates to:
  /// **'Eliminando...'**
  String get elementDetailRemovingButton;

  /// No description provided for @elementDetailAdminEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get elementDetailAdminEdit;

  /// No description provided for @elementDetailAdminMakeCommunity.
  ///
  /// In es, this message translates to:
  /// **'Comunitarizar'**
  String get elementDetailAdminMakeCommunity;

  /// No description provided for @elementDetailAdminMakeOfficial.
  ///
  /// In es, this message translates to:
  /// **'Oficializar'**
  String get elementDetailAdminMakeOfficial;

  /// No description provided for @elementDetailAdminLoading.
  ///
  /// In es, this message translates to:
  /// **'...'**
  String get elementDetailAdminLoading;

  /// No description provided for @elementDetailNoElement.
  ///
  /// In es, this message translates to:
  /// **'Elemento no encontrado.'**
  String get elementDetailNoElement;

  /// No description provided for @adminFormEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar Elemento'**
  String get adminFormEditTitle;

  /// No description provided for @adminFormCreateTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear Elemento Oficial'**
  String get adminFormCreateTitle;

  /// No description provided for @adminFormEditButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar Cambios'**
  String get adminFormEditButton;

  /// No description provided for @adminFormCreateButton.
  ///
  /// In es, this message translates to:
  /// **'Crear Elemento'**
  String get adminFormCreateButton;

  /// No description provided for @adminFormImageTitle.
  ///
  /// In es, this message translates to:
  /// **'Añadir portada'**
  String get adminFormImageTitle;

  /// No description provided for @adminFormImageGallery.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get adminFormImageGallery;

  /// No description provided for @adminFormImageUpload.
  ///
  /// In es, this message translates to:
  /// **'Subir'**
  String get adminFormImageUpload;

  /// No description provided for @adminFormImageUploading.
  ///
  /// In es, this message translates to:
  /// **'Subiendo...'**
  String get adminFormImageUploading;

  /// No description provided for @adminFormTitleLabel.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get adminFormTitleLabel;

  /// No description provided for @adminFormDescLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get adminFormDescLabel;

  /// No description provided for @adminFormTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo (Ej. Serie, Libro)'**
  String get adminFormTypeLabel;

  /// No description provided for @adminFormGenresLabel.
  ///
  /// In es, this message translates to:
  /// **'Géneros (separados por coma)'**
  String get adminFormGenresLabel;

  /// No description provided for @adminFormProgressTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos de Progreso (Opcional)'**
  String get adminFormProgressTitle;

  /// No description provided for @adminFormSequelsTitle.
  ///
  /// In es, this message translates to:
  /// **'Secuelas (Opcional)'**
  String get adminFormSequelsTitle;

  /// No description provided for @adminFormSequelsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elementos que van DESPUÉS de este.'**
  String get adminFormSequelsSubtitle;

  /// No description provided for @adminPanelSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre o email...'**
  String get adminPanelSearchHint;

  /// No description provided for @adminPanelFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get adminPanelFilterAll;

  /// No description provided for @adminPanelFilterMods.
  ///
  /// In es, this message translates to:
  /// **'Moderadores'**
  String get adminPanelFilterMods;

  /// No description provided for @adminPanelFilterAdmins.
  ///
  /// In es, this message translates to:
  /// **'Admins'**
  String get adminPanelFilterAdmins;

  /// No description provided for @adminPanelRoleMod.
  ///
  /// In es, this message translates to:
  /// **'Moderador'**
  String get adminPanelRoleMod;

  /// No description provided for @adminPanelRoleAdmin.
  ///
  /// In es, this message translates to:
  /// **'Administrador'**
  String get adminPanelRoleAdmin;

  /// No description provided for @adminPanelSaveButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar Cambios'**
  String get adminPanelSaveButton;

  /// No description provided for @adminPanelCreateElement.
  ///
  /// In es, this message translates to:
  /// **'Crear Elemento'**
  String get adminPanelCreateElement;

  /// No description provided for @adminPanelNoUsersFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron usuarios.'**
  String get adminPanelNoUsersFound;

  /// No description provided for @modPanelTitle.
  ///
  /// In es, this message translates to:
  /// **'Panel de Moderación'**
  String get modPanelTitle;

  /// No description provided for @modPanelProposalFrom.
  ///
  /// In es, this message translates to:
  /// **'Propuesto por: {username}'**
  String modPanelProposalFrom(String username);

  /// No description provided for @modPanelProposalType.
  ///
  /// In es, this message translates to:
  /// **'Tipo: {type}'**
  String modPanelProposalType(String type);

  /// No description provided for @modPanelProposalGenres.
  ///
  /// In es, this message translates to:
  /// **'Géneros: {genres}'**
  String modPanelProposalGenres(String genres);

  /// No description provided for @modPanelReject.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get modPanelReject;

  /// No description provided for @modPanelReview.
  ///
  /// In es, this message translates to:
  /// **'Revisar'**
  String get modPanelReview;

  /// No description provided for @modPanelNoPending.
  ///
  /// In es, this message translates to:
  /// **'¡Buen trabajo! No hay propuestas pendientes.'**
  String get modPanelNoPending;

  /// No description provided for @modPanelNoOthers.
  ///
  /// In es, this message translates to:
  /// **'No hay propuestas {status}.'**
  String modPanelNoOthers(String status);

  /// No description provided for @modPanelStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get modPanelStatusPending;

  /// No description provided for @modPanelStatusApproved.
  ///
  /// In es, this message translates to:
  /// **'Aprobadas'**
  String get modPanelStatusApproved;

  /// No description provided for @modPanelStatusRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazadas'**
  String get modPanelStatusRejected;

  /// No description provided for @modEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisar Propuesta'**
  String get modEditTitle;

  /// No description provided for @modEditImageTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin portada'**
  String get modEditImageTitle;

  /// No description provided for @modEditProgressTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos de Progreso (¡Obligatorio!)'**
  String get modEditProgressTitle;

  /// No description provided for @modEditSeriesEpisodesRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio para Series'**
  String get modEditSeriesEpisodesRequired;

  /// No description provided for @modEditBookChaptersRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio para Libros'**
  String get modEditBookChaptersRequired;

  /// No description provided for @modEditBookPagesRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio para Libros'**
  String get modEditBookPagesRequired;

  /// No description provided for @modEditUnitRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio'**
  String get modEditUnitRequired;

  /// No description provided for @modEditSubmitButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar y Aprobar'**
  String get modEditSubmitButton;

  /// No description provided for @catalogCardState.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get catalogCardState;

  /// No description provided for @catalogCardSeriesSeason.
  ///
  /// In es, this message translates to:
  /// **'T{season}'**
  String catalogCardSeriesSeason(int season);

  /// No description provided for @catalogCardSeriesEpisode.
  ///
  /// In es, this message translates to:
  /// **'Ep {episode}'**
  String catalogCardSeriesEpisode(int episode);

  /// No description provided for @catalogCardBookChapter.
  ///
  /// In es, this message translates to:
  /// **'Capítulo'**
  String get catalogCardBookChapter;

  /// No description provided for @catalogCardBookPage.
  ///
  /// In es, this message translates to:
  /// **'Página'**
  String get catalogCardBookPage;

  /// No description provided for @catalogCardBookChapterTotal.
  ///
  /// In es, this message translates to:
  /// **'Total: {total}'**
  String catalogCardBookChapterTotal(int total);

  /// No description provided for @catalogCardBookPageTotal.
  ///
  /// In es, this message translates to:
  /// **'Total: {total}'**
  String catalogCardBookPageTotal(int total);

  /// No description provided for @catalogCardUnitLabel.
  ///
  /// In es, this message translates to:
  /// **'{label}:'**
  String catalogCardUnitLabel(String label);

  /// No description provided for @catalogCardUnitProgress.
  ///
  /// In es, this message translates to:
  /// **'{current} / {total}'**
  String catalogCardUnitProgress(int current, int total);

  /// No description provided for @catalogCardSaveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar Progreso'**
  String get catalogCardSaveChanges;

  /// No description provided for @contentStatusOfficial.
  ///
  /// In es, this message translates to:
  /// **'OFICIAL'**
  String get contentStatusOfficial;

  /// No description provided for @contentStatusCommunity.
  ///
  /// In es, this message translates to:
  /// **'COMUNITARIO'**
  String get contentStatusCommunity;

  /// No description provided for @reviewCardBy.
  ///
  /// In es, this message translates to:
  /// **'Reseña de: {username}'**
  String reviewCardBy(String username);

  /// No description provided for @reviewCardNoText.
  ///
  /// In es, this message translates to:
  /// **'Este usuario no ha escrito un texto.'**
  String get reviewCardNoText;
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
