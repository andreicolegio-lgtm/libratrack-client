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
  String get loginTitle => 'Bienvenido a LibraTrack';

  @override
  String get loginSubtitle => 'Inicia sesión para continuar';

  @override
  String get loginButton => 'Iniciar Sesión';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Contraseña';

  @override
  String get loginOr => 'O';

  @override
  String get loginGoogle => 'Continuar con Google';

  @override
  String get loginRegisterPrompt => '¿No tienes cuenta? Regístrate';

  @override
  String get registerTitle => 'Registrarse';

  @override
  String get registerUsernameLabel => 'Nombre de Usuario';

  @override
  String get registerLoginPrompt => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get registrationSuccessAutoLogin =>
      '¡Registro exitoso! Ahora has iniciado sesión automáticamente.';

  @override
  String get passwordRulesTitle => 'Reglas de Contraseña';

  @override
  String get passwordRulesContent =>
      '\n• Mínimo 8 caracteres\n• Al menos 1 mayúscula\n• Al menos 1 minúscula\n• Al menos 1 número\n• Al menos 1 carácter especial (@\$!%*?&)\n';

  @override
  String get passwordRuleLength => 'Al menos 8 caracteres';

  @override
  String get passwordRuleUppercase => 'Al menos una mayúscula';

  @override
  String get passwordRuleLowercase => 'Al menos una minúscula';

  @override
  String get passwordRuleNumber => 'Al menos un número';

  @override
  String get passwordRuleSpecial => 'Al menos un carácter especial (@\$!%*?&)';

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
  String get catalogCardState => 'Estado';

  @override
  String catalogCardSeriesSeason(int season) {
    return 'T$season';
  }

  @override
  String catalogCardSeriesEpisode(int episode) {
    return 'Ep $episode';
  }

  @override
  String get catalogCardBookChapter => 'Capítulo';

  @override
  String get catalogCardBookPage => 'Página';

  @override
  String catalogCardBookChapterTotal(int total) {
    return 'Total: $total';
  }

  @override
  String catalogCardBookPageTotal(int total) {
    return 'Total: $total';
  }

  @override
  String catalogCardUnitLabel(String label) {
    return '$label:';
  }

  @override
  String catalogCardUnitProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get catalogCardSaveChanges => 'Guardar Progreso';

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
  String get elementDetailSynopsis => 'Sinopsis';

  @override
  String get elementDetailProgressDetails => 'Detalles del Progreso';

  @override
  String get elementDetailSeriesSeasons => 'Total Temporadas';

  @override
  String get elementDetailSeriesEpisodes => 'Episodios';

  @override
  String get elementDetailBookChapters => 'Total Capítulos';

  @override
  String get elementDetailBookPages => 'Total Páginas';

  @override
  String get elementDetailAnimeEpisodes => 'Total Episodios';

  @override
  String get elementDetailMangaChapters => 'Total Capítulos';

  @override
  String get elementDetailPrequels => 'Precuelas';

  @override
  String get elementDetailSequels => 'Secuelas';

  @override
  String elementDetailReviews(int count) {
    return 'Reseñas ($count)';
  }

  @override
  String get elementDetailAlreadyReviewed => 'Ya has reseñado';

  @override
  String get elementDetailWriteReview => 'Escribir Reseña';

  @override
  String get elementDetailNoReviews => 'Aún no hay reseñas para este elemento.';

  @override
  String get elementDetailAdminMakeCommunity => 'Comunitarizar';

  @override
  String get elementDetailAdminMakeOfficial => 'Oficializar';

  @override
  String get elementDetailAdminLoading => '...';

  @override
  String get reviewModalTitle => 'Escribir Reseña';

  @override
  String get reviewModalReviewLabel => 'Reseña (opcional)';

  @override
  String get reviewModalReviewHint => 'Escribe tu opinión...';

  @override
  String get reviewModalSubmitButton => 'Publicar Reseña';

  @override
  String reviewCardBy(String username) {
    return 'Reseña de: $username';
  }

  @override
  String get reviewCardNoText => 'Este usuario no ha escrito un texto.';

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

  @override
  String get settingsSystemDefault => 'Sistema (Por defecto)';

  @override
  String get dialogCloseButton => 'Cerrar';

  @override
  String get proposalFormTitle => 'Proponer Elemento';

  @override
  String get proposalFormTitleLabel => 'Título Sugerido';

  @override
  String get proposalFormDescLabel => 'Descripción Breve';

  @override
  String get proposalFormTypeLabel => 'Tipo (Ej. Serie, Libro, Anime)';

  @override
  String get proposalFormGenresLabel => 'Géneros (separados por coma)';

  @override
  String get proposalFormProgressTitle => 'Datos de Progreso (Opcional)';

  @override
  String get proposalFormSeriesEpisodesLabel => 'Episodios por Temporada';

  @override
  String get proposalFormSeriesEpisodesHint => 'Ej. 10,8,12 (para T1, T2, T3)';

  @override
  String get proposalFormBookChaptersLabel => 'Total Capítulos (Libro)';

  @override
  String get proposalFormBookPagesLabel => 'Total Páginas (Libro)';

  @override
  String get proposalFormAnimeEpisodesLabel => 'Total Episodios (Anime)';

  @override
  String get proposalFormMangaChaptersLabel => 'Total Capítulos (Manga)';

  @override
  String proposalFormNoProgress(String tipo) {
    return 'El tipo \"$tipo\" no requiere datos de progreso.';
  }

  @override
  String get proposalFormSubmitButton => 'Enviar Propuesta';

  @override
  String get adminFormEditTitle => 'Editar Elemento';

  @override
  String get adminFormCreateTitle => 'Crear Elemento Oficial';

  @override
  String get adminFormEditButton => 'Guardar Cambios';

  @override
  String get adminFormCreateButton => 'Crear Elemento';

  @override
  String get adminFormImageTitle => 'Añadir portada';

  @override
  String get adminFormImageGallery => 'Galería';

  @override
  String get adminFormImageUpload => 'Subir';

  @override
  String get adminFormImageUploading => 'Subiendo...';

  @override
  String get adminFormTitleLabel => 'Título';

  @override
  String get adminFormDescLabel => 'Descripción';

  @override
  String get adminFormTypeLabel => 'Tipo (Ej. Serie, Libro)';

  @override
  String get adminFormGenresLabel => 'Géneros (separados por coma)';

  @override
  String get adminFormProgressTitle => 'Datos de Progreso (Opcional)';

  @override
  String get adminFormSequelsTitle => 'Secuelas (Opcional)';

  @override
  String get adminFormSequelsSubtitle => 'Elementos que van DESPUÉS de este.';

  @override
  String get adminPanelSearchHint => 'Buscar por nombre o email...';

  @override
  String get adminPanelFilterAll => 'Todos';

  @override
  String get adminPanelFilterMods => 'Moderadores';

  @override
  String get adminPanelFilterAdmins => 'Admins';

  @override
  String get adminPanelRoleMod => 'Moderador';

  @override
  String get adminPanelRoleAdmin => 'Administrador';

  @override
  String get adminPanelSaveButton => 'Guardar Cambios';

  @override
  String get adminPanelCreateElement => 'Crear Elemento';

  @override
  String get adminPanelNoUsersFound => 'No se encontraron usuarios.';

  @override
  String get modPanelTitle => 'Panel de Moderación';

  @override
  String modPanelProposalFrom(String username) {
    return 'Propuesto por: $username';
  }

  @override
  String modPanelProposalType(String type) {
    return 'Tipo: $type';
  }

  @override
  String modPanelProposalGenres(String genres) {
    return 'Géneros: $genres';
  }

  @override
  String get modPanelReject => 'Rechazar';

  @override
  String get modPanelReview => 'Revisar';

  @override
  String get modPanelNoPending =>
      '¡Buen trabajo! No hay propuestas pendientes.';

  @override
  String modPanelNoOthers(String status) {
    return 'No hay propuestas $status.';
  }

  @override
  String get modPanelStatusPending => 'Pendientes';

  @override
  String get modPanelStatusApproved => 'Aprobadas';

  @override
  String get modPanelStatusRejected => 'Rechazadas';

  @override
  String get modEditProgressTitle => 'Datos de Progreso (¡Obligatorio!)';

  @override
  String get modEditSeriesEpisodesRequired =>
      'Este campo es obligatorio para Series';

  @override
  String get modEditBookChaptersRequired =>
      'Este campo es obligatorio para Libros';

  @override
  String get modEditBookPagesRequired =>
      'Este campo es obligatorio para Libros';

  @override
  String get modEditUnitRequired => 'Este campo es obligatorio';

  @override
  String get modEditSubmitButton => 'Guardar y Aprobar';

  @override
  String get totalEpisodes => 'Total de Episodios';

  @override
  String get duration => 'Duración';

  @override
  String get totalChapters => 'Total de Capítulos';

  @override
  String get totalPages => 'Total de Páginas';

  @override
  String get episodesPerSeason => 'Episodios por Temporada';

  @override
  String get snackbarCloseButton => 'CERRAR';

  @override
  String get snackbarLoginGoogleCancel => 'Inicio de sesión cancelado.';

  @override
  String get snackbarRegisterSuccess =>
      '¡Registro exitoso! Ahora has iniciado sesión automáticamente.';

  @override
  String get snackbarReviewPublished => '¡Reseña publicada!';

  @override
  String get snackbarReviewRatingRequired =>
      'Por favor, selecciona una valoración (1-5 estrellas).';

  @override
  String get snackbarProposalSent =>
      '¡Propuesta enviada con éxito! Gracias por tu contribución.';

  @override
  String get snackbarProfilePhotoUpdated => '¡Foto de perfil actualizada!';

  @override
  String get snackbarProfileNoChanges => 'No has realizado ningún cambio.';

  @override
  String get snackbarProfileUsernameUpdated =>
      '¡Nombre de usuario actualizado!';

  @override
  String get snackbarProfilePasswordUpdated =>
      '¡Contraseña actualizada con éxito!';

  @override
  String get snackbarCatalogAdded => '¡Añadido al catálogo!';

  @override
  String get snackbarCatalogRemoved => 'Elemento quitado del catálogo';

  @override
  String get snackbarCatalogStatusUpdated => 'Estado actualizado.';

  @override
  String get snackbarCatalogProgressSaved => 'Progreso guardado.';

  @override
  String get snackbarImageUploadSuccess => '¡Imagen subida!';

  @override
  String get snackbarImageUploadRequired =>
      'Por favor, sube una imagen de portada.';

  @override
  String get snackbarImageUploadRequiredApproval =>
      'Por favor, sube una imagen de portada antes de aprobar.';

  @override
  String get snackbarModProposalRejected => 'Propuesta rechazada (simulado).';

  @override
  String snackbarAdminRolesUpdated(String username) {
    return 'Roles de $username actualizados.';
  }

  @override
  String get snackbarAdminElementUpdated => '¡Elemento actualizado!';

  @override
  String get snackbarAdminElementCreated => '¡Elemento OFICIAL creado!';

  @override
  String get snackbarAdminStatusCommunity =>
      'Elemento marcado como COMUNITARIO.';

  @override
  String get snackbarAdminStatusOfficial => '¡Elemento marcado como OFICIAL!';

  @override
  String get snackbarFavoritoAdded => 'Añadido a favoritos';

  @override
  String get snackbarFavoritoRemoved => 'Eliminado de favoritos';

  @override
  String get validationUsernameRequired =>
      'El nombre de usuario es obligatorio.';

  @override
  String get validationUsernameLength450 =>
      'El nombre de usuario debe tener entre 4 y 50 caracteres.';

  @override
  String get validationEmailRequired => 'El email es obligatorio.';

  @override
  String get validationEmailInvalid => 'Introduce un email válido.';

  @override
  String get validationPasswordRequired => 'La contraseña es obligatoria.';

  @override
  String get validationPasswordCurrentRequired =>
      'La contraseña actual es obligatoria.';

  @override
  String get validationPasswordNewRequired =>
      'La nueva contraseña es obligatoria.';

  @override
  String get validationPasswordMin8 =>
      'La nueva contraseña debe tener al menos 8 caracteres.';

  @override
  String get validationPasswordComplexity =>
      'La contraseña debe cumplir con los requisitos de complejidad.';

  @override
  String get validationPasswordUnchanged => 'No has realizado ningún cambio.';

  @override
  String get validationPasswordRules =>
      'La contraseña debe tener al menos 8 caracteres, incluyendo una letra mayúscula, una letra minúscula, un número y un carácter especial.';

  @override
  String get validationElementIdRequired =>
      'El ID del elemento no puede ser nulo.';

  @override
  String get validationRatingRequired => 'La valoración es obligatoria.';

  @override
  String get validationRatingMin1 => 'La valoración mínima es 1.';

  @override
  String get validationRatingMax5 => 'La valoración máxima es 5.';

  @override
  String get validationReviewMax2000 =>
      'La reseña no puede exceder los 2000 caracteres.';

  @override
  String get validationTitleRequired => 'El título es obligatorio.';

  @override
  String get validationDescRequired => 'La descripción es obligatoria.';

  @override
  String get validationTypeRequired => 'El tipo es obligatorio.';

  @override
  String get validationGenresRequired => 'Los géneros son obligatorios.';

  @override
  String get validationGoogleTokenRequired =>
      'El token de Google no puede estar vacío.';

  @override
  String get validationModStatusRequired =>
      'Debe especificar el estado de moderador.';

  @override
  String get validationAdminStatusRequired =>
      'Debe especificar el estado de administrador.';

  @override
  String get validationSeasonMin1 => 'La temporada debe ser al menos 1.';

  @override
  String get validationUnitMin0 => 'La unidad debe ser al menos 0.';

  @override
  String get validationChapterMin0 => 'El capítulo debe ser al menos 0.';

  @override
  String get validationPageMin0 => 'La página debe ser al menos 0.';

  @override
  String get validationTypeNameRequired => 'El nombre del tipo es obligatorio.';

  @override
  String get validationTypeNameMax50 =>
      'El nombre del tipo debe tener 50 caracteres o menos.';

  @override
  String get validationGenreNameRequired =>
      'El nombre del género es obligatorio.';

  @override
  String get validationGenreNameMax50 =>
      'El nombre del género debe tener 50 caracteres o menos.';

  @override
  String get validationTitleMax255 =>
      'El título debe tener 255 caracteres o menos.';

  @override
  String get validationDescMax5000 =>
      'La descripción debe tener 5000 caracteres o menos.';

  @override
  String get validationEpisodesStringMax255 =>
      'La cadena de episodios es demasiado larga.';

  @override
  String get validationUnitsMin1 => 'El total de unidades debe ser al menos 1.';

  @override
  String get validationChaptersMin1 =>
      'El total de capítulos debe ser al menos 1.';

  @override
  String get validationPagesMin1 => 'El total de páginas debe ser al menos 1.';

  @override
  String get validationCommentMax500 =>
      'El comentario debe tener 500 caracteres o menos.';

  @override
  String get errorEmailAlreadyRegistered => 'El email ya está registrado.';

  @override
  String get errorUsernameAlreadyExists => 'El nombre de usuario ya existe.';

  @override
  String get errorPasswordIncorrect => 'La contraseña actual es incorrecta.';

  @override
  String get errorAlreadyReviewed => 'Ya has reseñado este elemento.';

  @override
  String get errorInvalidRatingRange => 'La valoración debe estar entre 1 y 5.';

  @override
  String get errorProposalAlreadyHandled =>
      'Esta propuesta ya ha sido gestionada.';

  @override
  String get errorTypeEmpty => 'El Tipo sugerido no puede estar vacío.';

  @override
  String get errorGenresEmpty =>
      'Los Géneros sugeridos no pueden estar vacíos.';

  @override
  String get errorGenreInvalid =>
      'Se debe proporcionar al menos un género válido.';

  @override
  String get errorFileEmpty => 'El archivo está vacío.';

  @override
  String get errorAlreadyInCatalog => 'Este elemento ya está en tu catálogo.';

  @override
  String get errorValidation => 'Error de validación.';

  @override
  String get errorIllegalArgument => 'Argumento no válido.';

  @override
  String get errorInternalServerError =>
      'Ocurrió un error inesperado. Por favor, inténtalo de nuevo más tarde.';

  @override
  String get errorAccessDenied =>
      'No tienes permiso para acceder a este recurso.';

  @override
  String get errorTokenExpired =>
      'Tu sesión ha caducado. Por favor, inicia sesión de nuevo.';

  @override
  String get errorTokenInvalid =>
      'Token inválido. Por favor, inicia sesión de nuevo.';

  @override
  String get errorInvalidCredentials => 'Email o contraseña incorrectos.';

  @override
  String get errorGoogleTokenInvalid => 'Token de Google inválido.';

  @override
  String get errorGoogleTokenError => 'Error al verificar el token de Google.';

  @override
  String get errorRefreshTokenRequired => 'Se requiere un token de refresco.';

  @override
  String get errorRefreshTokenNotFound => 'Token de refresco no encontrado.';

  @override
  String get errorRefreshTokenExpired =>
      'Tu sesión ha caducado. Por favor, inicia sesión de nuevo.';

  @override
  String get errorProposalNotFound => 'Propuesta no encontrada.';

  @override
  String get errorNotInCatalog => 'Este elemento no está en tu catálogo.';

  @override
  String get errorReviewerNotFound => 'Revisor no encontrado.';

  @override
  String get errorFileSave => 'Error al guardar el archivo.';

  @override
  String get errorUserNotFound => 'Usuario no encontrado.';

  @override
  String errorUnexpected(String error) {
    return 'Error inesperado: $error';
  }

  @override
  String errorLoadingElement(String error) {
    return 'Error al cargar el elemento:\n$error';
  }

  @override
  String errorLoadingElements(String error) {
    return 'Error al cargar elementos: $error';
  }

  @override
  String errorLoadingReviews(String error) {
    return 'Error al cargar las reseñas: $error';
  }

  @override
  String errorLoadingProposals(String error) {
    return 'Error al cargar:\n$error';
  }

  @override
  String errorLoadingUsers(String error) {
    return 'Error: $error';
  }

  @override
  String errorLoadingCatalog(String error) {
    return 'Error: $error';
  }

  @override
  String errorImagePick(String error) {
    return 'Error al seleccionar imagen: $error';
  }

  @override
  String errorImageUpload(String error) {
    return 'Error al subir imagen: $error';
  }

  @override
  String errorSaving(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String errorUpdating(String error) {
    return 'Error al actualizar: $error';
  }

  @override
  String errorApproving(String error) {
    return 'Error al aprobar: $error';
  }

  @override
  String errorUpdatingRoles(String error) {
    return 'Error al actualizar roles: $error';
  }

  @override
  String get typeAnime => 'Anime';

  @override
  String get typeMovie => 'Película';

  @override
  String get typeVideoGame => 'Videojuego';

  @override
  String get typeManga => 'Manga';

  @override
  String get typeManhwa => 'Manhwa';

  @override
  String get typeBook => 'Libro';

  @override
  String get typeSeries => 'Serie';

  @override
  String get genreAction => 'Acción';

  @override
  String get genreAdventure => 'Aventura';

  @override
  String get genreComedy => 'Comedia';

  @override
  String get genreDrama => 'Drama';

  @override
  String get genreFantasy => 'Fantasía';

  @override
  String get genreHorror => 'Terror';

  @override
  String get genreMystery => 'Misterio';

  @override
  String get genreRomance => 'Romance';

  @override
  String get genreSciFi => 'Ciencia Ficción';

  @override
  String get genreSliceOfLife => 'Recuentos de la vida';

  @override
  String get genrePsychological => 'Psicológico';

  @override
  String get genreThriller => 'Thriller';

  @override
  String get genreHistorical => 'Histórico';

  @override
  String get genreCrime => 'Crimen';

  @override
  String get genreFamily => 'Familia';

  @override
  String get genreWar => 'Guerra';

  @override
  String get genreCyberpunk => 'Cyberpunk';

  @override
  String get genrePostApocalyptic => 'Post-apocalíptico';

  @override
  String get genreShonen => 'Shonen';

  @override
  String get genreShojo => 'Shojo';

  @override
  String get genreSeinen => 'Seinen';

  @override
  String get genreJosei => 'Josei';

  @override
  String get genreIsekai => 'Isekai';

  @override
  String get genreMecha => 'Mecha';

  @override
  String get genreHarem => 'Harem';

  @override
  String get genreEcchi => 'Ecchi';

  @override
  String get genreYaoi => 'Yaoi';

  @override
  String get genreYuri => 'Yuri';

  @override
  String get genreMartialArts => 'Artes Marciales';

  @override
  String get genreSchool => 'Escolar';

  @override
  String get genreRPG => 'RPG';

  @override
  String get genreShooter => 'Shooter';

  @override
  String get genrePlatformer => 'Plataformas';

  @override
  String get genreStrategy => 'Estrategia';

  @override
  String get genrePuzzle => 'Puzzle';

  @override
  String get genreFighting => 'Lucha';

  @override
  String get genreSports => 'Deportes';

  @override
  String get genreRacing => 'Carreras';

  @override
  String get genreOpenWorld => 'Mundo Abierto';

  @override
  String get genreRoguelike => 'Roguelike';

  @override
  String get genreMOBA => 'MOBA';

  @override
  String get genreBattleRoyale => 'Battle Royale';

  @override
  String get genreSimulator => 'Simulador';

  @override
  String get genreSurvivalHorror => 'Terror de supervivencia';

  @override
  String get genreBiography => 'Biografía';

  @override
  String get genreEssay => 'Ensayo';

  @override
  String get genrePoetry => 'Poesía';

  @override
  String get genreSelfHelp => 'Autoayuda';

  @override
  String get genreBusiness => 'Negocios';

  @override
  String get genreNoir => 'Novela Negra';

  @override
  String get genreMagicalRealism => 'Realismo Mágico';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get labelUnknown => 'Desconocido';

  @override
  String get contentStatusOfficial => 'OFICIAL';

  @override
  String get contentStatusCommunity => 'COMUNITARIO';

  @override
  String get adminPanelTitle => 'Panel de Administración';

  @override
  String get searchUsersHint => 'Buscar usuarios...';

  @override
  String get adminTabAll => 'Todos';

  @override
  String get adminTabMods => 'Moderadores';

  @override
  String get adminTabAdmins => 'Administradores';

  @override
  String get adminLabelYou => 'TÚ';

  @override
  String get settingsSectionAppearance => 'Apariencia';

  @override
  String get settingsSectionLanguage => 'Idioma';

  @override
  String get settingsVersion => 'Versión';

  @override
  String get catalogProgressNoChanges => 'No has realizado cambios.';

  @override
  String get catalogProgressSaved => 'Progreso guardado';

  @override
  String get dialogNotesTitle => 'Notas Personales';

  @override
  String get dialogNotesHint => 'Escribe tus pensamientos...';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionSave => 'Guardar';

  @override
  String get tooltipNotes => 'Notas';

  @override
  String get tooltipSaveProgress => 'Guardar progreso';

  @override
  String get unitMin => 'min';

  @override
  String get unitHr => 'hr(s)';

  @override
  String get unitCap => 'Cap';

  @override
  String get unitPage => 'Pág';

  @override
  String get unitSeason => 'T';

  @override
  String get unitEp => 'Eps';

  @override
  String get inputTemp => 'Temp';

  @override
  String get inputEpisodes => 'Episodios';

  @override
  String get inputChapter => 'Capítulo';

  @override
  String get inputPage => 'Página';

  @override
  String get inputTime => 'Tiempo';

  @override
  String get inputEpisode => 'Episodio';

  @override
  String get catalogTabFavorites => 'Favoritos';

  @override
  String get catalogSearchHint => 'Buscar en mi catálogo...';

  @override
  String get catalogEmpty => 'No se encontraron elementos.';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionDelete => 'Borrar';

  @override
  String get reviewCreateTitle => 'Crear Reseña';

  @override
  String get reviewEditTitle => 'Editar Reseña';

  @override
  String get reviewPublished => 'Reseña publicada con éxito';

  @override
  String get reviewUpdated => 'Reseña actualizada con éxito';

  @override
  String get actionPublish => 'Publicar';

  @override
  String get actionUpdate => 'Actualizar';

  @override
  String get elementDetailNoElement => 'Elemento no encontrado';

  @override
  String get elementDetailAddButton => 'Añadir a lista';

  @override
  String get elementDetailRemovingButton => 'Eliminando...';

  @override
  String get elementDetailAddingButton => 'Añadiendo...';

  @override
  String get elementDetailRemoveButton => 'Quitar';

  @override
  String get elementDetailAdminEdit => 'Editar Elemento';

  @override
  String get labelSynopsis => 'Sinopsis';

  @override
  String get labelAvailability => 'Disponibilidad';

  @override
  String get labelProgressDetails => 'Detalles de Progreso';

  @override
  String get labelChronology => 'Cronología';

  @override
  String get labelReviews => 'Reseñas';

  @override
  String get labelModActions => 'Acciones de Moderación';

  @override
  String get labelTotalChapters => 'Total Capítulos';

  @override
  String get labelTotalPages => 'Total Páginas';

  @override
  String get labelDuration => 'Duración';

  @override
  String get labelTotalEpisodes => 'Total Episodios';

  @override
  String get labelPrequel => 'Precuela';

  @override
  String get labelSequel => 'Secuela';

  @override
  String get labelNoReviews => 'No hay reseñas aún.';

  @override
  String get labelReviewed => 'Reseñado';

  @override
  String get labelRatings => 'valoraciones';

  @override
  String get actionWriteReview => 'Escribir Reseña';

  @override
  String get dialogDeleteReviewTitle => '¿Borrar reseña?';

  @override
  String get dialogDeleteReviewContent => 'Esta acción no se puede deshacer.';

  @override
  String get snackbarReviewDeleted => 'Reseña eliminada';

  @override
  String get snackbarReviewUpdated => 'Reseña actualizada';

  @override
  String get tooltipFavorite => 'Favorito';

  @override
  String get tooltipSortOldest => 'Más antiguas primero';

  @override
  String get tooltipSortNewest => 'Más recientes primero';

  @override
  String formatSeasonEpisodes(String season, String episodes) {
    return 'Temporada $season: $episodes Episodios';
  }

  @override
  String formatDuration(int hours, int minutes) {
    return '$hours hr $minutes min';
  }

  @override
  String get createdElementsTitle => 'Historial de Creaciones';

  @override
  String get searchByTitleHint => 'Buscar por título...';

  @override
  String get createdElementsEmpty => 'No has creado elementos aún.';

  @override
  String get labelCreatedBy => 'Creado por';

  @override
  String get adminFormErrorReviewFields =>
      'Por favor, revisa los campos marcados en rojo.';

  @override
  String get adminFormUpdateSuccess => 'Elemento actualizado con éxito.';

  @override
  String get adminFormCreateSuccess => 'Elemento creado con éxito.';

  @override
  String get validationEpisodesRequired =>
      'El número de episodios es obligatorio.';

  @override
  String get validationChaptersRequired =>
      'El número de capítulos es obligatorio.';

  @override
  String get validationPagesRequired => 'Las páginas son obligatorias.';

  @override
  String get validationSeasonsRequired =>
      'Debes indicar los episodios por temporada.';

  @override
  String get validationDurationRequired => 'La duración es obligatoria.';

  @override
  String get validationAvailabilityRequired =>
      'La disponibilidad es obligatoria.';

  @override
  String get labelGenre => 'Género';

  @override
  String get labelProgressData => 'Datos de Progreso';

  @override
  String get labelSequels => 'Secuelas (Opcional)';

  @override
  String get labelNoRelations => 'Sin relaciones seleccionadas';

  @override
  String get labelContentStatus => 'Estado del Contenido';

  @override
  String get actionAddRelation => 'Añadir Relación';

  @override
  String get searchHintShort => 'Escribe al menos 2 caracteres...';

  @override
  String get searchNoResults => 'No se encontraron resultados.';

  @override
  String get moderationPanelTitle => 'Panel de Moderación';

  @override
  String get searchProposalsHint => 'Buscar propuestas...';

  @override
  String get tabPending => 'Pendientes';

  @override
  String get tabApproved => 'Aprobados';

  @override
  String get tabRejected => 'Rechazados';

  @override
  String get actionHistory => 'Historial';

  @override
  String get actionCreateElement => 'Crear Elemento';

  @override
  String get actionReject => 'Rechazar';

  @override
  String get actionReview => 'Revisar';

  @override
  String get actionComments => 'Comentarios';

  @override
  String get actionClose => 'Cerrar';

  @override
  String get dialogRejectTitle => 'Rechazar Propuesta';

  @override
  String get dialogRejectInstruction => 'Indica el motivo del rechazo:';

  @override
  String get dialogRejectHint => 'Ej. Información duplicada o incorrecta';

  @override
  String get dialogReviewCommentsTitle => 'Comentarios de Revisión';

  @override
  String get dialogReviewCommentsEmpty => 'Sin comentarios registrados.';

  @override
  String get snackbarProposalRejected => 'Propuesta rechazada';

  @override
  String get labelApprovedBy => 'Aprobado por:';

  @override
  String get labelRejectedBy => 'Rechazado por:';

  @override
  String get labelProposedBy => 'Propuesto por:';

  @override
  String get modEditTitle => 'Revisar Propuesta';

  @override
  String get modEditImageTitle => 'Imagen Sugerida';

  @override
  String get modEditReviewComment => 'Comentarios de revisión (Opcional)';

  @override
  String get snackbarModProposalApproved =>
      'Propuesta aprobada y elemento creado con éxito';

  @override
  String get actionSaveAndApprove => 'Guardar y Aprobar';

  @override
  String get validationRequired => 'Requerido';

  @override
  String get actionRemovePhoto => 'Eliminar foto actual';

  @override
  String get snackbarProfilePhotoRemoved => 'Foto de perfil eliminada';

  @override
  String get errorRemovingPhoto => 'Error al eliminar foto';

  @override
  String get labelProgressDataOptional => 'Datos de Progreso (Opcional)';

  @override
  String get labelAvailabilityOptional => 'Disponibilidad (Opcional)';

  @override
  String get hintSelectAvailability => 'Seleccionar Disponibilidad';

  @override
  String get validationRequiredField =>
      'Por favor, revisa los campos obligatorios.';

  @override
  String get statusReleasing => 'En Emisión';

  @override
  String get statusFinished => 'Finalizado';

  @override
  String get statusAnnounced => 'Anunciado';

  @override
  String get statusCancelled => 'Cancelado';

  @override
  String get statusPaused => 'Pausado';

  @override
  String get statusAvailable => 'Disponible';

  @override
  String get hintDurationFormat => '120 min / 02:00';

  @override
  String get helperSeriesEpisodes =>
      'Introduce el número de episodios por temporada separados por comas.';

  @override
  String get tooltipFilters => 'Filtros';

  @override
  String get searchHintDefault => 'Buscar...';

  @override
  String get modalFiltersTitle => 'Filtros';

  @override
  String get actionReset => 'Restablecer';

  @override
  String get actionApplyFilters => 'Aplicar Filtros';

  @override
  String get filterSortBy => 'Ordenar por';

  @override
  String get sortRecent => 'Recientes';

  @override
  String get sortAlpha => 'Alfabéticamente';

  @override
  String get filterTypes => 'Tipos';

  @override
  String get filterGenres => 'Géneros';

  @override
  String get errorLoadingFilters => 'Error cargando filtros';

  @override
  String get hintFilterGenres => 'Filtrar géneros';

  @override
  String get actionOther => 'Otro';

  @override
  String get dialogAddGenreTitle => 'Añadir Género';

  @override
  String get hintGenreName => 'Nombre del género';

  @override
  String get actionAdd => 'Añadir';
}
