import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class ErrorTranslator {
  static String translate(BuildContext context, String errorKey) {
    final loc = AppLocalizations.of(context);
    switch (errorKey) {
      case 'EMAIL_ALREADY_REGISTERED':
        return loc?.errorEmailAlreadyRegistered ?? errorKey;
      case 'USERNAME_ALREADY_EXISTS':
        return loc?.errorUsernameAlreadyExists ?? errorKey;
      case 'PASSWORD_INCORRECT':
        return loc?.errorPasswordIncorrect ?? errorKey;
      case 'ALREADY_REVIEWED':
        return loc?.errorAlreadyReviewed ?? errorKey;
      case 'INVALID_RATING_RANGE':
        return loc?.errorInvalidRatingRange ?? errorKey;
      case 'PROPOSAL_ALREADY_HANDLED':
        return loc?.errorProposalAlreadyHandled ?? errorKey;
      case 'TYPE_EMPTY':
        return loc?.errorTypeEmpty ?? errorKey;
      case 'GENRES_EMPTY':
        return loc?.errorGenresEmpty ?? errorKey;
      case 'GENRE_INVALID':
        return loc?.errorGenreInvalid ?? errorKey;
      case 'FILE_EMPTY':
        return loc?.errorFileEmpty ?? errorKey;
      case 'ALREADY_IN_CATALOG':
        return loc?.errorAlreadyInCatalog ?? errorKey;
      case 'VALIDATION_ERROR':
        return loc?.errorValidation ?? errorKey;
      case 'ILLEGAL_ARGUMENT':
        return loc?.errorIllegalArgument ?? errorKey;
      case 'INTERNAL_SERVER_ERROR':
        return loc?.errorInternalServerError ?? errorKey;
      case 'FORBIDDEN':
        return loc?.errorInternalServerError ?? errorKey;
      case 'RESOURCE_NOT_FOUND':
        return loc?.errorInternalServerError ?? errorKey;
      case 'ELEMENT_NOT_FOUND':
        return loc?.errorInternalServerError ?? errorKey;
      case 'INVALID_USER_TOKEN':
        return loc?.errorInternalServerError ?? errorKey;
      case 'INVALID_FILE_NAME':
        return loc?.errorInternalServerError ?? errorKey;
      case 'FILE_SAVE_ERROR':
        return loc?.errorInternalServerError ?? errorKey;
      default:
        return loc?.errorInternalServerError ?? errorKey;
    }
  }
}
