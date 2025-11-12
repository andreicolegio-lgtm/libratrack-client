// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'LibraTrack';

  @override
  String get loginButton => 'Iniciar Sesión';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Contraseña';

  @override
  String get loginEmailRequired => 'El email es obligatorio.';

  @override
  String get loginEmailInvalid => 'Introduce un email válido.';

  @override
  String get loginPasswordRequired => 'La contraseña es obligatoria.';

  @override
  String get loginRegisterPrompt => '¿No tienes cuenta? Regístrate';

  @override
  String get registerTitle => 'Registrarse';

  @override
  String get registerUsernameLabel => 'Nombre de Usuario';

  @override
  String get registerUsernameRequired => 'El nombre de usuario es obligatorio.';

  @override
  String get registerUsernameLength => 'Debe tener al menos 4 caracteres.';

  @override
  String get registerPasswordLength => 'Debe tener al menos 8 caracteres.';

  @override
  String get registerLoginPrompt => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get bottomNavCatalog => 'Catálogo';

  @override
  String get bottomNavSearch => 'Buscar';

  @override
  String get bottomNavProfile => 'Perfil';

  @override
  String get catalogTitle => 'Mi Catálogo';

  @override
  String get catalogInProgress => 'En Progreso';

  @override
  String get catalogPending => 'Pendiente';

  @override
  String get catalogFinished => 'Terminado';

  @override
  String get catalogDropped => 'Abandonado';

  @override
  String catalogEmptyState(String estado) {
    return 'No hay elementos en estado: $estado';
  }

  @override
  String get searchExploreType => 'Explorar por Tipo';

  @override
  String get searchExploreGenre => 'Explorar por Género';

  @override
  String get searchFieldHint => 'Buscar por título...';

  @override
  String get searchEmptyState =>
      'No se encontraron elementos con el filtro aplicado.';

  @override
  String get searchProposeButton => 'Proponer Elemento';

  @override
  String get profileUserData => 'Datos de Usuario';

  @override
  String get profileSaveButton => 'Guardar Cambios';

  @override
  String get profileChangePassword => 'Cambiar Contraseña';

  @override
  String get profileCurrentPassword => 'Contraseña actual';

  @override
  String get profileNewPassword => 'Nueva contraseña';

  @override
  String get profileModPanelButton => 'Panel de Moderación';

  @override
  String get profileAdminPanelButton => 'Panel de Administrador';

  @override
  String get profileLogoutButton => 'Cerrar Sesión';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsDarkMode => 'Modo Oscuro';

  @override
  String get settingsDarkModeOn => 'Activado';

  @override
  String get settingsDarkModeOff => 'Desactivado';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSpanish => 'Español';

  @override
  String get settingsLanguageEnglish => 'Inglés';
}
