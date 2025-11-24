import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class ErrorTranslator {
  static String translate(BuildContext context, String errorKey) {
    final loc = AppLocalizations.of(context);

    if (loc == null) {
      return errorKey;
    }

    switch (errorKey) {
      case 'E_INVALID_CREDENTIALS':
        return loc.errorInvalidCredentials;
      case 'E_ACCESS_DENIED':
      case 'FORBIDDEN':
        return loc.errorAccessDenied;
      case 'E_TOKEN_EXPIRED':
        return loc.errorTokenExpired;
      case 'E_TOKEN_INVALID':
        return loc.errorTokenInvalid;
      case 'E_GOOGLE_TOKEN_INVALID':
        return loc.errorGoogleTokenInvalid;
      case 'E_GOOGLE_TOKEN_ERROR':
        return loc.errorGoogleTokenError;
      case 'E_REFRESH_TOKEN_REQUIRED':
        return loc.errorRefreshTokenRequired;
      case 'E_REFRESH_TOKEN_NOT_FOUND':
        return loc.errorRefreshTokenNotFound;
      case 'E_REFRESH_TOKEN_EXPIRED':
        return loc.errorRefreshTokenExpired;
      case 'PROPOSAL_NOT_FOUND':
        return loc.errorProposalNotFound;
      case 'NOT_IN_CATALOG':
      case 'CATALOG_ENTRY_NOT_FOUND':
        return loc.errorNotInCatalog;
      case 'EMAIL_ALREADY_REGISTERED':
        return loc.errorEmailAlreadyRegistered;
      case 'USERNAME_ALREADY_EXISTS':
        return loc.errorUsernameAlreadyExists;
      case 'PASSWORD_INCORRECT':
        return loc.errorPasswordIncorrect;
      case 'ALREADY_REVIEWED':
        return loc.errorAlreadyReviewed;
      case 'INVALID_RATING_RANGE':
        return loc.errorInvalidRatingRange;
      case 'PROPOSAL_ALREADY_HANDLED':
        return loc.errorProposalAlreadyHandled;
      case 'TYPE_EMPTY':
        return loc.errorTypeEmpty;
      case 'GENRES_EMPTY':
        return loc.errorGenresEmpty;
      case 'GENRE_INVALID':
        return loc.errorGenreInvalid;
      case 'FILE_EMPTY':
        return loc.errorFileEmpty;
      case 'ALREADY_IN_CATALOG':
        return loc.errorAlreadyInCatalog;
      case 'VALIDATION_ERROR':
        return loc.errorValidation;
      case 'ILLEGAL_ARGUMENT':
        return loc.errorIllegalArgument;
      case 'INTERNAL_SERVER_ERROR':
        return loc.errorInternalServerError;
      case 'USER_NOT_FOUND':
        return loc.errorUserNotFound;
      case 'REVIEWER_NOT_FOUND':
        return loc.errorReviewerNotFound;
      case 'FILE_UPLOAD_ERROR':
        return loc.errorImageUpload('');
      case 'FILE_SAVE_ERROR':
        return loc.errorFileSave;

      case 'RESOURCE_NOT_FOUND':
      case 'ELEMENT_NOT_FOUND':
        return loc.elementDetailNoElement;
      case 'INVALID_USER_TOKEN':
        return loc.errorTokenInvalid;

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
      case 'VALIDATION_PASSWORD_CURRENT_REQUIRED':
        return loc.validationPasswordCurrentRequired;
      case 'VALIDATION_PASSWORD_NEW_REQUIRED':
        return loc.validationPasswordNewRequired;
      case 'VALIDATION_PASSWORD_MIN_8':
        return loc.validationPasswordMin8;
      case 'VALIDATION_ELEMENT_ID_REQUIRED':
        return loc.validationElementIdRequired;
      case 'VALIDATION_RATING_REQUIRED':
        return loc.validationRatingRequired;
      case 'VALIDATION_RATING_MIN_1':
        return loc.validationRatingMin1;
      case 'VALIDATION_RATING_MAX_5':
        return loc.validationRatingMax5;
      case 'VALIDATION_REVIEW_MAX_2000':
        return loc.validationReviewMax2000;
      case 'VALIDATION_TITLE_REQUIRED':
        return loc.validationTitleRequired;
      case 'VALIDATION_DESC_REQUIRED':
        return loc.validationDescRequired;
      case 'VALIDATION_TYPE_REQUIRED':
        return loc.validationTypeRequired;
      case 'VALIDATION_GENRES_REQUIRED':
        return loc.validationGenresRequired;
      case 'VALIDATION_GOOGLE_TOKEN_REQUIRED':
        return loc.validationGoogleTokenRequired;
      case 'VALIDATION_MOD_STATUS_REQUIRED':
        return loc.validationModStatusRequired;
      case 'VALIDATION_ADMIN_STATUS_REQUIRED':
        return loc.validationAdminStatusRequired;

      case 'VALIDATION_SEASON_MIN_1':
        return loc.validationSeasonMin1;
      case 'VALIDATION_UNIT_MIN_0':
        return loc.validationUnitMin0;
      case 'VALIDATION_CHAPTER_MIN_0':
        return loc.validationChapterMin0;
      case 'VALIDATION_PAGE_MIN_0':
        return loc.validationPageMin0;
      case 'VALIDATION_TYPE_NAME_REQUIRED':
        return loc.validationTypeNameRequired;
      case 'VALIDATION_TYPE_NAME_MAX_50':
        return loc.validationTypeNameMax50;
      case 'VALIDATION_GENRE_NAME_REQUIRED':
        return loc.validationGenreNameRequired;
      case 'VALIDATION_GENRE_NAME_MAX_50':
        return loc.validationGenreNameMax50;
      case 'VALIDATION_TITLE_MAX_255':
        return loc.validationTitleMax255;
      case 'VALIDATION_DESC_MAX_5000':
        return loc.validationDescMax5000;
      case 'VALIDATION_EPISODES_STRING_MAX_255':
        return loc.validationEpisodesStringMax255;
      case 'VALIDATION_UNITS_MIN_1':
        return loc.validationUnitsMin1;
      case 'VALIDATION_CHAPTERS_MIN_1':
        return loc.validationChaptersMin1;
      case 'VALIDATION_PAGES_MIN_1':
        return loc.validationPagesMin1;
      case 'VALIDATION_COMMENT_MAX_500':
        return loc.validationCommentMax500;

      default:
        return errorKey;
    }
  }
}
