import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Utilidad para traducir códigos de error de la API a mensajes amigables para el usuario.
class ErrorTranslator {
  static String translate(BuildContext context, String errorKey) {
    final loc = AppLocalizations.of(context);

    // Limpieza básica por si el error viene con prefijos
    final key = errorKey.trim();

    switch (key) {
      // --- Errores de Autenticación ---
      case 'E_INVALID_CREDENTIALS':
      case 'Bad credentials': // Spring Security default sometimes
        return loc.errorInvalidCredentials;
      case 'E_ACCESS_DENIED':
      case 'FORBIDDEN':
        return loc.errorAccessDenied;
      case 'E_TOKEN_EXPIRED':
        return loc.errorTokenExpired;
      case 'E_TOKEN_INVALID':
        return loc.errorTokenInvalid;
      case 'E_REFRESH_TOKEN_REQUIRED':
        return loc.errorRefreshTokenRequired;
      case 'E_REFRESH_TOKEN_NOT_FOUND':
        return loc.errorRefreshTokenNotFound;
      case 'E_REFRESH_TOKEN_EXPIRED':
        return loc.errorRefreshTokenExpired;
      case 'E_GOOGLE_TOKEN_INVALID':
        return loc.errorGoogleTokenInvalid;
      case 'E_GOOGLE_TOKEN_ERROR':
        return loc.errorGoogleTokenError;
      case 'INVALID_USER_TOKEN':
        return loc.errorTokenInvalid;

      // --- Errores de Negocio ---
      case 'USER_NOT_FOUND':
        return loc.errorUserNotFound;
      case 'EMAIL_ALREADY_REGISTERED':
        return loc.errorEmailAlreadyRegistered;
      case 'USERNAME_ALREADY_EXISTS':
        return loc.errorUsernameAlreadyExists;
      case 'PASSWORD_INCORRECT':
        return loc.errorPasswordIncorrect;
      case 'PASSWORD_UNCHANGED': // Añadido backend key
        return loc.validationPasswordUnchanged;

      case 'ELEMENT_NOT_FOUND':
      case 'RESOURCE_NOT_FOUND':
        return loc.elementDetailNoElement;

      case 'CATALOG_ENTRY_NOT_FOUND':
      case 'NOT_IN_CATALOG':
        return loc.errorNotInCatalog;
      case 'ALREADY_IN_CATALOG':
        return loc.errorAlreadyInCatalog;

      case 'ALREADY_REVIEWED':
        return loc.errorAlreadyReviewed;

      case 'PROPOSAL_NOT_FOUND':
        return loc.errorProposalNotFound;
      case 'PROPOSAL_ALREADY_HANDLED':
        return loc.errorProposalAlreadyHandled;

      // --- Errores de Validación (Backend Keys) ---
      case 'VALIDATION_ERROR':
      case 'VALIDATION_FAILED':
        return loc.errorValidation;

      case 'VALIDATION_USERNAME_REQUIRED':
        return loc.validationUsernameRequired;
      case 'VALIDATION_USERNAME_LENGTH_4_50':
        return loc.validationUsernameLength450;
      case 'VALIDATION_EMAIL_REQUIRED':
        return loc.validationEmailRequired;
      case 'VALIDATION_EMAIL_INVALID':
        return loc.validationEmailInvalid;
      case 'VALIDATION_PASSWORD_REQUIRED':
        return loc.validationPasswordRequired;
      case 'VALIDATION_PASSWORD_COMPLEXITY':
        return loc.validationPasswordComplexity;

      case 'VALIDATION_TITLE_REQUIRED':
        return loc.validationTitleRequired;
      case 'VALIDATION_DESC_REQUIRED':
        return loc.validationDescRequired;
      case 'VALIDATION_TYPE_REQUIRED':
        return loc.validationTypeRequired;
      case 'VALIDATION_GENRES_REQUIRED':
        return loc.validationGenresRequired;

      case 'VALIDATION_RATING_REQUIRED':
        return loc.validationRatingRequired;
      case 'VALIDATION_RATING_MIN_1':
        return loc.validationRatingMin1;
      case 'VALIDATION_RATING_MAX_5':
        return loc.validationRatingMax5;
      case 'INVALID_RATING_RANGE':
        return loc.errorInvalidRatingRange;

      // --- Errores Genéricos/Técnicos ---
      case 'FILE_EMPTY':
        return loc.errorFileEmpty;
      case 'FILE_SAVE_ERROR':
        return loc.errorFileSave;
      case 'FILE_UPLOAD_ERROR':
        return loc.errorImageUpload(''); // Generic msg
      case 'INTERNAL_SERVER_ERROR':
        return loc.errorInternalServerError;
      case 'ILLEGAL_ARGUMENT':
        return loc.errorIllegalArgument;

      default:
        // Si el error contiene un mensaje legible (ej. "Error: ..."), lo mostramos
        if (key.startsWith('Error') || key.contains('Exception')) {
          return loc.errorUnexpected(key);
        }
        return key; // Devolvemos la clave tal cual si no hay traducción
    }
  }
}
