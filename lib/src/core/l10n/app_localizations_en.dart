// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LibraTrack';

  @override
  String get loginButton => 'Sign In';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginRegisterPrompt => 'Don\'t have an account? Register';

  @override
  String get registerTitle => 'Register';

  @override
  String get registerUsernameLabel => 'Username';

  @override
  String get registerLoginPrompt => 'Already have an account? Sign In';

  @override
  String get bottomNavCatalog => 'Catalog';

  @override
  String get bottomNavSearch => 'Search';

  @override
  String get bottomNavProfile => 'Profile';

  @override
  String get catalogTitle => 'My Catalog';

  @override
  String get catalogInProgress => 'In Progress';

  @override
  String get catalogPending => 'Pending';

  @override
  String get catalogFinished => 'Finished';

  @override
  String get catalogDropped => 'Dropped';

  @override
  String catalogEmptyState(String estado) {
    return 'No items found in state: $estado';
  }

  @override
  String get searchExploreType => 'Explore by Type';

  @override
  String get searchExploreGenre => 'Explore by Genre';

  @override
  String get searchFieldHint => 'Search by title...';

  @override
  String get searchEmptyState =>
      'No elements were found with the applied filter.';

  @override
  String get searchProposeButton => 'Propose Element';

  @override
  String get profileUserData => 'User Data';

  @override
  String get profileSaveButton => 'Save Changes';

  @override
  String get profileChangePassword => 'Change Password';

  @override
  String get profileCurrentPassword => 'Current Password';

  @override
  String get profileNewPassword => 'New Password';

  @override
  String get profileModPanelButton => 'Moderation Panel';

  @override
  String get profileAdminPanelButton => 'Admin Panel';

  @override
  String get profileLogoutButton => 'Log Out';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsDarkModeOn => 'Enabled';

  @override
  String get settingsDarkModeOff => 'Disabled';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSpanish => 'Spanish';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get validationUsernameRequired => 'Username is required.';

  @override
  String get validationUsernameLength450 =>
      'Username must be between 4 and 50 characters.';

  @override
  String get validationEmailRequired => 'Email is required.';

  @override
  String get validationEmailInvalid => 'Please enter a valid email.';

  @override
  String get validationPasswordRequired => 'Password is required.';

  @override
  String get validationPasswordCurrentRequired =>
      'Current password is required.';

  @override
  String get validationPasswordNewRequired => 'New password is required.';

  @override
  String get validationPasswordMin8 =>
      'New password must be at least 8 characters.';

  @override
  String get validationElementIdRequired => 'Element ID cannot be null.';

  @override
  String get validationRatingRequired => 'Rating is required.';

  @override
  String get validationRatingMin1 => 'Rating must be at least 1.';

  @override
  String get validationRatingMax5 => 'Rating must be 5 or less.';

  @override
  String get validationReviewMax2000 => 'Review cannot exceed 2000 characters.';

  @override
  String get validationTitleRequired => 'Title is required.';

  @override
  String get validationDescRequired => 'Description is required.';

  @override
  String get validationTypeRequired => 'Type is required.';

  @override
  String get validationGenresRequired => 'Genres are required.';

  @override
  String get validationGoogleTokenRequired => 'Google token cannot be empty.';

  @override
  String get validationModStatusRequired =>
      'Moderator status must be specified.';

  @override
  String get validationAdminStatusRequired => 'Admin status must be specified.';

  @override
  String get errorEmailAlreadyRegistered => 'Email is already registered.';

  @override
  String get errorUsernameAlreadyExists => 'Username already exists.';

  @override
  String get errorPasswordIncorrect => 'Incorrect password.';

  @override
  String get errorAlreadyReviewed => 'You have already reviewed this item.';

  @override
  String get errorInvalidRatingRange => 'Rating must be between 1 and 5.';

  @override
  String get errorProposalAlreadyHandled =>
      'This proposal has already been handled.';

  @override
  String get errorTypeEmpty => 'Type cannot be empty.';

  @override
  String get errorGenresEmpty => 'Genres cannot be empty.';

  @override
  String get errorGenreInvalid => 'At least one valid genre must be provided.';

  @override
  String get errorFileEmpty => 'File is empty.';

  @override
  String get errorAlreadyInCatalog => 'This item is already in your catalog.';

  @override
  String get errorValidation => 'Validation error.';

  @override
  String get errorIllegalArgument => 'Illegal argument.';

  @override
  String get errorInternalServerError =>
      'An unexpected error occurred. Please try again later.';

  @override
  String get errorAccessDenied =>
      'You do not have permission to access this resource.';

  @override
  String get errorTokenExpired =>
      'Your session has expired. Please log in again.';

  @override
  String get errorTokenInvalid => 'Invalid token. Please log in again.';

  @override
  String get errorInvalidCredentials => 'Incorrect email or password.';
}
