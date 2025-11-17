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
  String get loginTitle => 'Welcome to LibraTrack';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get loginButton => 'Sign In';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginOr => 'OR';

  @override
  String get loginGoogle => 'Continue with Google';

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
  String get settingsSystemDefault => 'System (Default)';

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

  @override
  String errorUnexpected(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String errorLoadingFilters(String error) {
    return 'Error loading filters: $error';
  }

  @override
  String errorLoadingElement(String error) {
    return 'Error loading element:\n$error';
  }

  @override
  String errorLoadingElements(String error) {
    return 'Error loading elements: $error';
  }

  @override
  String errorLoadingReviews(String error) {
    return 'Error loading reviews: $error';
  }

  @override
  String errorLoadingProposals(String error) {
    return 'Error loading:\n$error';
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
    return 'Error selecting image: $error';
  }

  @override
  String errorImageUpload(String error) {
    return 'Error uploading image: $error';
  }

  @override
  String errorSaving(String error) {
    return 'Error saving: $error';
  }

  @override
  String errorUpdating(String error) {
    return 'Error updating: $error';
  }

  @override
  String errorApproving(String error) {
    return 'Error approving: $error';
  }

  @override
  String errorUpdatingRoles(String error) {
    return 'Error updating roles: $error';
  }

  @override
  String get snackbarCloseButton => 'CLOSE';

  @override
  String get snackbarLoginGoogleCancel => 'Sign in canceled.';

  @override
  String get snackbarRegisterSuccess =>
      'Registration successful! Please sign in.';

  @override
  String get snackbarReviewPublished => 'Review published!';

  @override
  String get snackbarReviewRatingRequired =>
      'Please select a rating (1-5 stars).';

  @override
  String get snackbarProposalSent =>
      'Proposal sent successfully! Thank you for your contribution.';

  @override
  String get snackbarProfilePhotoUpdated => 'Profile photo updated!';

  @override
  String get snackbarProfileNoChanges => 'You haven\'t made any changes.';

  @override
  String get snackbarProfileUsernameUpdated => 'Username updated!';

  @override
  String get snackbarProfilePasswordUpdated => 'Password updated successfully!';

  @override
  String get snackbarCatalogAdded => 'Added to catalog!';

  @override
  String get snackbarCatalogRemoved => 'Removed from catalog';

  @override
  String get snackbarCatalogStatusUpdated => 'Status updated.';

  @override
  String get snackbarCatalogProgressSaved => 'Progress saved.';

  @override
  String get snackbarImageUploadSuccess => 'Image uploaded!';

  @override
  String get snackbarImageUploadRequired => 'Please upload a cover image.';

  @override
  String get snackbarImageUploadRequiredApproval =>
      'Please upload a cover image before approving.';

  @override
  String get snackbarModProposalApproved => 'Proposal approved!';

  @override
  String get snackbarModProposalRejected => 'Proposal rejected (simulated).';

  @override
  String snackbarAdminRolesUpdated(String username) {
    return 'Roles for $username updated.';
  }

  @override
  String get snackbarAdminElementUpdated => 'Element updated!';

  @override
  String get snackbarAdminElementCreated => 'OFFICIAL element created!';

  @override
  String get snackbarAdminStatusCommunity => 'Element marked as COMMUNITY.';

  @override
  String get snackbarAdminStatusOfficial => 'Element marked as OFFICIAL!';

  @override
  String get reviewModalTitle => 'Write Review';

  @override
  String get reviewModalReviewLabel => 'Review (optional)';

  @override
  String get reviewModalReviewHint => 'Write your opinion...';

  @override
  String get reviewModalSubmitButton => 'Publish Review';

  @override
  String get proposalFormTitle => 'Propose Element';

  @override
  String get proposalFormTitleLabel => 'Suggested Title';

  @override
  String get proposalFormDescLabel => 'Brief Description';

  @override
  String get proposalFormTypeLabel => 'Type (e.g. Series, Book, Anime)';

  @override
  String get proposalFormGenresLabel => 'Genres (comma separated)';

  @override
  String get proposalFormProgressTitle => 'Progress Data (Optional)';

  @override
  String get proposalFormSeriesEpisodesLabel => 'Episodes per Season';

  @override
  String get proposalFormSeriesEpisodesHint => 'e.g. 10,8,12 (for S1, S2, S3)';

  @override
  String get proposalFormBookChaptersLabel => 'Total Chapters (Book)';

  @override
  String get proposalFormBookPagesLabel => 'Total Pages (Book)';

  @override
  String get proposalFormAnimeEpisodesLabel => 'Total Episodes (Anime)';

  @override
  String get proposalFormMangaChaptersLabel => 'Total Chapters (Manga)';

  @override
  String proposalFormNoProgress(String tipo) {
    return 'The type \"$tipo\" does not require progress data.';
  }

  @override
  String get proposalFormSubmitButton => 'Send Proposal';

  @override
  String get elementDetailSynopsis => 'Synopsis';

  @override
  String get elementDetailProgressDetails => 'Progress Details';

  @override
  String get elementDetailSeriesSeasons => 'Total Seasons';

  @override
  String get elementDetailSeriesEpisodes => 'Episodes';

  @override
  String get elementDetailBookChapters => 'Total Chapters';

  @override
  String get elementDetailBookPages => 'Total Pages';

  @override
  String get elementDetailAnimeEpisodes => 'Total Episodes';

  @override
  String get elementDetailMangaChapters => 'Total Chapters';

  @override
  String get elementDetailPrequels => 'Prequels';

  @override
  String get elementDetailSequels => 'Sequels';

  @override
  String elementDetailReviews(int count) {
    return 'Reviews ($count)';
  }

  @override
  String get elementDetailAlreadyReviewed => 'Already reviewed';

  @override
  String get elementDetailWriteReview => 'Write Review';

  @override
  String get elementDetailNoReviews =>
      'There are no reviews for this item yet.';

  @override
  String get elementDetailAddButton => 'Add to My Catalog';

  @override
  String get elementDetailAddingButton => 'Adding...';

  @override
  String get elementDetailRemoveButton => 'Remove from catalog';

  @override
  String get elementDetailRemovingButton => 'Removing...';

  @override
  String get elementDetailAdminEdit => 'Edit';

  @override
  String get elementDetailAdminMakeCommunity => 'Make Community';

  @override
  String get elementDetailAdminMakeOfficial => 'Make Official';

  @override
  String get elementDetailAdminLoading => '...';

  @override
  String get elementDetailNoElement => 'Element not found.';

  @override
  String get adminFormEditTitle => 'Edit Element';

  @override
  String get adminFormCreateTitle => 'Create Official Element';

  @override
  String get adminFormEditButton => 'Save Changes';

  @override
  String get adminFormCreateButton => 'Create Element';

  @override
  String get adminFormImageTitle => 'Add cover';

  @override
  String get adminFormImageGallery => 'Gallery';

  @override
  String get adminFormImageUpload => 'Upload';

  @override
  String get adminFormImageUploading => 'Uploading...';

  @override
  String get adminFormTitleLabel => 'Title';

  @override
  String get adminFormDescLabel => 'Description';

  @override
  String get adminFormTypeLabel => 'Type (e.g. Series, Book)';

  @override
  String get adminFormGenresLabel => 'Genres (comma separated)';

  @override
  String get adminFormProgressTitle => 'Progress Data (Optional)';

  @override
  String get adminFormSequelsTitle => 'Sequels (Optional)';

  @override
  String get adminFormSequelsSubtitle => 'Elements that come AFTER this one.';

  @override
  String get adminPanelSearchHint => 'Search by name or email...';

  @override
  String get adminPanelFilterAll => 'All';

  @override
  String get adminPanelFilterMods => 'Moderators';

  @override
  String get adminPanelFilterAdmins => 'Admins';

  @override
  String get adminPanelRoleMod => 'Moderator';

  @override
  String get adminPanelRoleAdmin => 'Administrator';

  @override
  String get adminPanelSaveButton => 'Save Changes';

  @override
  String get adminPanelCreateElement => 'Create Element';

  @override
  String get adminPanelNoUsersFound => 'No users found.';

  @override
  String get modPanelTitle => 'Moderation Panel';

  @override
  String modPanelProposalFrom(String username) {
    return 'Proposed by: $username';
  }

  @override
  String modPanelProposalType(String type) {
    return 'Type: $type';
  }

  @override
  String modPanelProposalGenres(String genres) {
    return 'Genres: $genres';
  }

  @override
  String get modPanelReject => 'Reject';

  @override
  String get modPanelReview => 'Review';

  @override
  String get modPanelNoPending => 'Good job! No pending proposals.';

  @override
  String modPanelNoOthers(String status) {
    return 'No $status proposals.';
  }

  @override
  String get modPanelStatusPending => 'Pending';

  @override
  String get modPanelStatusApproved => 'Approved';

  @override
  String get modPanelStatusRejected => 'Rejected';

  @override
  String get modEditTitle => 'Review Proposal';

  @override
  String get modEditImageTitle => 'No cover';

  @override
  String get modEditProgressTitle => 'Progress Data (Required!)';

  @override
  String get modEditSeriesEpisodesRequired =>
      'This field is required for Series';

  @override
  String get modEditBookChaptersRequired => 'This field is required for Books';

  @override
  String get modEditBookPagesRequired => 'This field is required for Books';

  @override
  String get modEditUnitRequired => 'This field is required';

  @override
  String get modEditSubmitButton => 'Save and Approve';

  @override
  String get catalogCardState => 'Status';

  @override
  String catalogCardSeriesSeason(int season) {
    return 'S$season';
  }

  @override
  String catalogCardSeriesEpisode(int episode) {
    return 'Ep $episode';
  }

  @override
  String get catalogCardBookChapter => 'Chapter';

  @override
  String get catalogCardBookPage => 'Page';

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
  String get catalogCardSaveChanges => 'Save Progress';

  @override
  String get contentStatusOfficial => 'OFFICIAL';

  @override
  String get contentStatusCommunity => 'COMMUNITY';

  @override
  String reviewCardBy(String username) {
    return 'Review by: $username';
  }

  @override
  String get reviewCardNoText => 'This user did not write a review.';

  @override
  String get elementNotFound => 'Element not found.';

  @override
  String get elementReloadError => 'Error reloading the updated element.';

  @override
  String get adminNotFound => 'Admin not found';

  @override
  String userNotFoundById(String userId) {
    return 'User not found with id: $userId';
  }

  @override
  String userNotFoundByUsername(String username) {
    return 'User not found with username: $username';
  }
}
