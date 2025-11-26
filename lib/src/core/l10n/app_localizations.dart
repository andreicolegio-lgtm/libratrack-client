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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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

  /// The main title of the application
  ///
  /// In en, this message translates to:
  /// **'LibraTrack'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to LibraTrack'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSubtitle;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginOr.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get loginOr;

  /// No description provided for @loginGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginGoogle;

  /// No description provided for @loginRegisterPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get loginRegisterPrompt;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTitle;

  /// No description provided for @registerUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get registerUsernameLabel;

  /// No description provided for @registerLoginPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get registerLoginPrompt;

  /// No description provided for @registrationSuccessAutoLogin.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! You are now logged in automatically.'**
  String get registrationSuccessAutoLogin;

  /// No description provided for @passwordRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Rules'**
  String get passwordRulesTitle;

  /// No description provided for @passwordRulesContent.
  ///
  /// In en, this message translates to:
  /// **'\n• Minimum 8 characters\n• At least 1 uppercase letter\n• At least 1 lowercase letter\n• At least 1 number\n• At least 1 special character (@\$!%*?&)\n'**
  String get passwordRulesContent;

  /// No description provided for @passwordRuleLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordRuleLength;

  /// No description provided for @passwordRuleUppercase.
  ///
  /// In en, this message translates to:
  /// **'At least one uppercase letter'**
  String get passwordRuleUppercase;

  /// No description provided for @passwordRuleLowercase.
  ///
  /// In en, this message translates to:
  /// **'At least one lowercase letter'**
  String get passwordRuleLowercase;

  /// No description provided for @passwordRuleNumber.
  ///
  /// In en, this message translates to:
  /// **'At least one number'**
  String get passwordRuleNumber;

  /// No description provided for @passwordRuleSpecial.
  ///
  /// In en, this message translates to:
  /// **'At least one special character (@\$!%*?&)'**
  String get passwordRuleSpecial;

  /// No description provided for @bottomNavCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get bottomNavCatalog;

  /// No description provided for @bottomNavSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get bottomNavSearch;

  /// No description provided for @bottomNavProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get bottomNavProfile;

  /// No description provided for @catalogTitle.
  ///
  /// In en, this message translates to:
  /// **'My Catalog'**
  String get catalogTitle;

  /// No description provided for @catalogInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get catalogInProgress;

  /// No description provided for @catalogPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get catalogPending;

  /// No description provided for @catalogFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get catalogFinished;

  /// No description provided for @catalogDropped.
  ///
  /// In en, this message translates to:
  /// **'Dropped'**
  String get catalogDropped;

  /// No description provided for @catalogEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No items found in state: {estado}'**
  String catalogEmptyState(String estado);

  /// No description provided for @catalogCardState.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get catalogCardState;

  /// No description provided for @catalogCardSeriesSeason.
  ///
  /// In en, this message translates to:
  /// **'S{season}'**
  String catalogCardSeriesSeason(int season);

  /// No description provided for @catalogCardSeriesEpisode.
  ///
  /// In en, this message translates to:
  /// **'Ep {episode}'**
  String catalogCardSeriesEpisode(int episode);

  /// No description provided for @catalogCardBookChapter.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get catalogCardBookChapter;

  /// No description provided for @catalogCardBookPage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get catalogCardBookPage;

  /// No description provided for @catalogCardBookChapterTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {total}'**
  String catalogCardBookChapterTotal(int total);

  /// No description provided for @catalogCardBookPageTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {total}'**
  String catalogCardBookPageTotal(int total);

  /// No description provided for @catalogCardUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'{label}:'**
  String catalogCardUnitLabel(String label);

  /// No description provided for @catalogCardUnitProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String catalogCardUnitProgress(int current, int total);

  /// No description provided for @catalogCardSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Progress'**
  String get catalogCardSaveChanges;

  /// No description provided for @searchExploreType.
  ///
  /// In en, this message translates to:
  /// **'Explore by Type'**
  String get searchExploreType;

  /// No description provided for @searchExploreGenre.
  ///
  /// In en, this message translates to:
  /// **'Explore by Genre'**
  String get searchExploreGenre;

  /// No description provided for @searchFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title...'**
  String get searchFieldHint;

  /// No description provided for @searchEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No elements were found with the applied filter.'**
  String get searchEmptyState;

  /// No description provided for @searchProposeButton.
  ///
  /// In en, this message translates to:
  /// **'Propose Element'**
  String get searchProposeButton;

  /// No description provided for @elementDetailSynopsis.
  ///
  /// In en, this message translates to:
  /// **'Synopsis'**
  String get elementDetailSynopsis;

  /// No description provided for @elementDetailProgressDetails.
  ///
  /// In en, this message translates to:
  /// **'Progress Details'**
  String get elementDetailProgressDetails;

  /// No description provided for @elementDetailSeriesSeasons.
  ///
  /// In en, this message translates to:
  /// **'Total Seasons'**
  String get elementDetailSeriesSeasons;

  /// No description provided for @elementDetailSeriesEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get elementDetailSeriesEpisodes;

  /// No description provided for @elementDetailBookChapters.
  ///
  /// In en, this message translates to:
  /// **'Total Chapters'**
  String get elementDetailBookChapters;

  /// No description provided for @elementDetailBookPages.
  ///
  /// In en, this message translates to:
  /// **'Total Pages'**
  String get elementDetailBookPages;

  /// No description provided for @elementDetailAnimeEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Total Episodes'**
  String get elementDetailAnimeEpisodes;

  /// No description provided for @elementDetailMangaChapters.
  ///
  /// In en, this message translates to:
  /// **'Total Chapters'**
  String get elementDetailMangaChapters;

  /// No description provided for @elementDetailPrequels.
  ///
  /// In en, this message translates to:
  /// **'Prequels'**
  String get elementDetailPrequels;

  /// No description provided for @elementDetailSequels.
  ///
  /// In en, this message translates to:
  /// **'Sequels'**
  String get elementDetailSequels;

  /// No description provided for @elementDetailReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews ({count})'**
  String elementDetailReviews(int count);

  /// No description provided for @elementDetailAlreadyReviewed.
  ///
  /// In en, this message translates to:
  /// **'Already reviewed'**
  String get elementDetailAlreadyReviewed;

  /// No description provided for @elementDetailWriteReview.
  ///
  /// In en, this message translates to:
  /// **'Write Review'**
  String get elementDetailWriteReview;

  /// No description provided for @elementDetailNoReviews.
  ///
  /// In en, this message translates to:
  /// **'There are no reviews for this item yet.'**
  String get elementDetailNoReviews;

  /// No description provided for @elementDetailAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add to My Catalog'**
  String get elementDetailAddButton;

  /// No description provided for @elementDetailAddingButton.
  ///
  /// In en, this message translates to:
  /// **'Adding...'**
  String get elementDetailAddingButton;

  /// No description provided for @elementDetailRemoveButton.
  ///
  /// In en, this message translates to:
  /// **'Remove from catalog'**
  String get elementDetailRemoveButton;

  /// No description provided for @elementDetailRemovingButton.
  ///
  /// In en, this message translates to:
  /// **'Removing...'**
  String get elementDetailRemovingButton;

  /// No description provided for @elementDetailAdminEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get elementDetailAdminEdit;

  /// No description provided for @elementDetailAdminMakeCommunity.
  ///
  /// In en, this message translates to:
  /// **'Make Community'**
  String get elementDetailAdminMakeCommunity;

  /// No description provided for @elementDetailAdminMakeOfficial.
  ///
  /// In en, this message translates to:
  /// **'Make Official'**
  String get elementDetailAdminMakeOfficial;

  /// No description provided for @elementDetailAdminLoading.
  ///
  /// In en, this message translates to:
  /// **'...'**
  String get elementDetailAdminLoading;

  /// No description provided for @elementDetailNoElement.
  ///
  /// In en, this message translates to:
  /// **'Element not found.'**
  String get elementDetailNoElement;

  /// No description provided for @contentStatusOfficial.
  ///
  /// In en, this message translates to:
  /// **'OFFICIAL'**
  String get contentStatusOfficial;

  /// No description provided for @contentStatusCommunity.
  ///
  /// In en, this message translates to:
  /// **'COMMUNITY'**
  String get contentStatusCommunity;

  /// No description provided for @reviewModalTitle.
  ///
  /// In en, this message translates to:
  /// **'Write Review'**
  String get reviewModalTitle;

  /// No description provided for @reviewModalReviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Review (optional)'**
  String get reviewModalReviewLabel;

  /// No description provided for @reviewModalReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Write your opinion...'**
  String get reviewModalReviewHint;

  /// No description provided for @reviewModalSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Publish Review'**
  String get reviewModalSubmitButton;

  /// No description provided for @reviewCardBy.
  ///
  /// In en, this message translates to:
  /// **'Review by: {username}'**
  String reviewCardBy(String username);

  /// No description provided for @reviewCardNoText.
  ///
  /// In en, this message translates to:
  /// **'This user did not write a text review.'**
  String get reviewCardNoText;

  /// No description provided for @profileUserData.
  ///
  /// In en, this message translates to:
  /// **'User Data'**
  String get profileUserData;

  /// No description provided for @profileSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get profileSaveButton;

  /// No description provided for @profileChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get profileChangePassword;

  /// No description provided for @profileCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get profileCurrentPassword;

  /// No description provided for @profileNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get profileNewPassword;

  /// No description provided for @profileModPanelButton.
  ///
  /// In en, this message translates to:
  /// **'Moderation Panel'**
  String get profileModPanelButton;

  /// No description provided for @profileAdminPanelButton.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get profileAdminPanelButton;

  /// No description provided for @profileLogoutButton.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get profileLogoutButton;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsDarkModeOn.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get settingsDarkModeOn;

  /// No description provided for @settingsDarkModeOff.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get settingsDarkModeOff;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get settingsLanguageSpanish;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System (Default)'**
  String get settingsSystemDefault;

  /// No description provided for @dialogCloseButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dialogCloseButton;

  /// No description provided for @proposalFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Propose Element'**
  String get proposalFormTitle;

  /// No description provided for @proposalFormTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggested Title'**
  String get proposalFormTitleLabel;

  /// No description provided for @proposalFormDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Brief Description'**
  String get proposalFormDescLabel;

  /// No description provided for @proposalFormTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type (e.g. Series, Book, Anime)'**
  String get proposalFormTypeLabel;

  /// No description provided for @proposalFormGenresLabel.
  ///
  /// In en, this message translates to:
  /// **'Genres (comma separated)'**
  String get proposalFormGenresLabel;

  /// No description provided for @proposalFormProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress Data (Optional)'**
  String get proposalFormProgressTitle;

  /// No description provided for @proposalFormSeriesEpisodesLabel.
  ///
  /// In en, this message translates to:
  /// **'Episodes per Season'**
  String get proposalFormSeriesEpisodesLabel;

  /// No description provided for @proposalFormSeriesEpisodesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 10,8,12 (for S1, S2, S3)'**
  String get proposalFormSeriesEpisodesHint;

  /// No description provided for @proposalFormBookChaptersLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Chapters (Book)'**
  String get proposalFormBookChaptersLabel;

  /// No description provided for @proposalFormBookPagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Pages (Book)'**
  String get proposalFormBookPagesLabel;

  /// No description provided for @proposalFormAnimeEpisodesLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Episodes (Anime)'**
  String get proposalFormAnimeEpisodesLabel;

  /// No description provided for @proposalFormMangaChaptersLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Chapters (Manga)'**
  String get proposalFormMangaChaptersLabel;

  /// No description provided for @proposalFormNoProgress.
  ///
  /// In en, this message translates to:
  /// **'The type \"{tipo}\" does not require progress data.'**
  String proposalFormNoProgress(String tipo);

  /// No description provided for @proposalFormSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Send Proposal'**
  String get proposalFormSubmitButton;

  /// No description provided for @adminFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Element'**
  String get adminFormEditTitle;

  /// No description provided for @adminFormCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Official Element'**
  String get adminFormCreateTitle;

  /// No description provided for @adminFormEditButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get adminFormEditButton;

  /// No description provided for @adminFormCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Element'**
  String get adminFormCreateButton;

  /// No description provided for @adminFormImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Add cover'**
  String get adminFormImageTitle;

  /// No description provided for @adminFormImageGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get adminFormImageGallery;

  /// No description provided for @adminFormImageUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get adminFormImageUpload;

  /// No description provided for @adminFormImageUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get adminFormImageUploading;

  /// No description provided for @adminFormTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get adminFormTitleLabel;

  /// No description provided for @adminFormDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get adminFormDescLabel;

  /// No description provided for @adminFormTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type (e.g. Series, Book)'**
  String get adminFormTypeLabel;

  /// No description provided for @adminFormGenresLabel.
  ///
  /// In en, this message translates to:
  /// **'Genres (comma separated)'**
  String get adminFormGenresLabel;

  /// No description provided for @adminFormProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress Data (Optional)'**
  String get adminFormProgressTitle;

  /// No description provided for @adminFormSequelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sequels (Optional)'**
  String get adminFormSequelsTitle;

  /// No description provided for @adminFormSequelsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Elements that come AFTER this one.'**
  String get adminFormSequelsSubtitle;

  /// No description provided for @adminPanelSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email...'**
  String get adminPanelSearchHint;

  /// No description provided for @adminPanelFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminPanelFilterAll;

  /// No description provided for @adminPanelFilterMods.
  ///
  /// In en, this message translates to:
  /// **'Moderators'**
  String get adminPanelFilterMods;

  /// No description provided for @adminPanelFilterAdmins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get adminPanelFilterAdmins;

  /// No description provided for @adminPanelRoleMod.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get adminPanelRoleMod;

  /// No description provided for @adminPanelRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get adminPanelRoleAdmin;

  /// No description provided for @adminPanelSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get adminPanelSaveButton;

  /// No description provided for @adminPanelCreateElement.
  ///
  /// In en, this message translates to:
  /// **'Create Element'**
  String get adminPanelCreateElement;

  /// No description provided for @adminPanelNoUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found.'**
  String get adminPanelNoUsersFound;

  /// No description provided for @modPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Moderation Panel'**
  String get modPanelTitle;

  /// No description provided for @modPanelProposalFrom.
  ///
  /// In en, this message translates to:
  /// **'Proposed by: {username}'**
  String modPanelProposalFrom(String username);

  /// No description provided for @modPanelProposalType.
  ///
  /// In en, this message translates to:
  /// **'Type: {type}'**
  String modPanelProposalType(String type);

  /// No description provided for @modPanelProposalGenres.
  ///
  /// In en, this message translates to:
  /// **'Genres: {genres}'**
  String modPanelProposalGenres(String genres);

  /// No description provided for @modPanelReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get modPanelReject;

  /// No description provided for @modPanelReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get modPanelReview;

  /// No description provided for @modPanelNoPending.
  ///
  /// In en, this message translates to:
  /// **'Good job! No pending proposals.'**
  String get modPanelNoPending;

  /// No description provided for @modPanelNoOthers.
  ///
  /// In en, this message translates to:
  /// **'No {status} proposals.'**
  String modPanelNoOthers(String status);

  /// No description provided for @modPanelStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get modPanelStatusPending;

  /// No description provided for @modPanelStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get modPanelStatusApproved;

  /// No description provided for @modPanelStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get modPanelStatusRejected;

  /// No description provided for @modEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Proposal'**
  String get modEditTitle;

  /// No description provided for @modEditImageTitle.
  ///
  /// In en, this message translates to:
  /// **'No cover'**
  String get modEditImageTitle;

  /// No description provided for @modEditProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress Data (Required!)'**
  String get modEditProgressTitle;

  /// No description provided for @modEditSeriesEpisodesRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required for Series'**
  String get modEditSeriesEpisodesRequired;

  /// No description provided for @modEditBookChaptersRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required for Books'**
  String get modEditBookChaptersRequired;

  /// No description provided for @modEditBookPagesRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required for Books'**
  String get modEditBookPagesRequired;

  /// No description provided for @modEditUnitRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get modEditUnitRequired;

  /// No description provided for @modEditSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Save and Approve'**
  String get modEditSubmitButton;

  /// No description provided for @totalEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Total Episodes'**
  String get totalEpisodes;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @totalChapters.
  ///
  /// In en, this message translates to:
  /// **'Total Chapters'**
  String get totalChapters;

  /// No description provided for @totalPages.
  ///
  /// In en, this message translates to:
  /// **'Total Pages'**
  String get totalPages;

  /// No description provided for @episodesPerSeason.
  ///
  /// In en, this message translates to:
  /// **'Episodes per Season'**
  String get episodesPerSeason;

  /// No description provided for @snackbarCloseButton.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get snackbarCloseButton;

  /// No description provided for @snackbarLoginGoogleCancel.
  ///
  /// In en, this message translates to:
  /// **'Sign in cancelled.'**
  String get snackbarLoginGoogleCancel;

  /// No description provided for @snackbarRegisterSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! You are now logged in automatically.'**
  String get snackbarRegisterSuccess;

  /// No description provided for @snackbarReviewPublished.
  ///
  /// In en, this message translates to:
  /// **'Review published!'**
  String get snackbarReviewPublished;

  /// No description provided for @snackbarReviewRatingRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a rating (1-5 stars).'**
  String get snackbarReviewRatingRequired;

  /// No description provided for @snackbarProposalSent.
  ///
  /// In en, this message translates to:
  /// **'Proposal sent successfully! Thank you for your contribution.'**
  String get snackbarProposalSent;

  /// No description provided for @snackbarProfilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated!'**
  String get snackbarProfilePhotoUpdated;

  /// No description provided for @snackbarProfileNoChanges.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t made any changes.'**
  String get snackbarProfileNoChanges;

  /// No description provided for @snackbarProfileUsernameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Username updated!'**
  String get snackbarProfileUsernameUpdated;

  /// No description provided for @snackbarProfilePasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully!'**
  String get snackbarProfilePasswordUpdated;

  /// No description provided for @snackbarCatalogAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to catalog!'**
  String get snackbarCatalogAdded;

  /// No description provided for @snackbarCatalogRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from catalog'**
  String get snackbarCatalogRemoved;

  /// No description provided for @snackbarCatalogStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status updated.'**
  String get snackbarCatalogStatusUpdated;

  /// No description provided for @snackbarCatalogProgressSaved.
  ///
  /// In en, this message translates to:
  /// **'Progress saved.'**
  String get snackbarCatalogProgressSaved;

  /// No description provided for @snackbarImageUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded!'**
  String get snackbarImageUploadSuccess;

  /// No description provided for @snackbarImageUploadRequired.
  ///
  /// In en, this message translates to:
  /// **'Please upload a cover image.'**
  String get snackbarImageUploadRequired;

  /// No description provided for @snackbarImageUploadRequiredApproval.
  ///
  /// In en, this message translates to:
  /// **'Please upload a cover image before approving.'**
  String get snackbarImageUploadRequiredApproval;

  /// No description provided for @snackbarModProposalApproved.
  ///
  /// In en, this message translates to:
  /// **'Proposal approved!'**
  String get snackbarModProposalApproved;

  /// No description provided for @snackbarModProposalRejected.
  ///
  /// In en, this message translates to:
  /// **'Proposal rejected (simulated).'**
  String get snackbarModProposalRejected;

  /// No description provided for @snackbarAdminRolesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Roles for {username} updated.'**
  String snackbarAdminRolesUpdated(String username);

  /// No description provided for @snackbarAdminElementUpdated.
  ///
  /// In en, this message translates to:
  /// **'Element updated!'**
  String get snackbarAdminElementUpdated;

  /// No description provided for @snackbarAdminElementCreated.
  ///
  /// In en, this message translates to:
  /// **'OFFICIAL element created!'**
  String get snackbarAdminElementCreated;

  /// No description provided for @snackbarAdminStatusCommunity.
  ///
  /// In en, this message translates to:
  /// **'Element marked as COMMUNITY.'**
  String get snackbarAdminStatusCommunity;

  /// No description provided for @snackbarAdminStatusOfficial.
  ///
  /// In en, this message translates to:
  /// **'Element marked as OFFICIAL!'**
  String get snackbarAdminStatusOfficial;

  /// No description provided for @snackbarFavoritoAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get snackbarFavoritoAdded;

  /// No description provided for @snackbarFavoritoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get snackbarFavoritoRemoved;

  /// No description provided for @validationUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required.'**
  String get validationUsernameRequired;

  /// No description provided for @validationUsernameLength450.
  ///
  /// In en, this message translates to:
  /// **'Username must be between 4 and 50 characters.'**
  String get validationUsernameLength450;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email.'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordCurrentRequired.
  ///
  /// In en, this message translates to:
  /// **'Current password is required.'**
  String get validationPasswordCurrentRequired;

  /// No description provided for @validationPasswordNewRequired.
  ///
  /// In en, this message translates to:
  /// **'New password is required.'**
  String get validationPasswordNewRequired;

  /// No description provided for @validationPasswordMin8.
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 8 characters.'**
  String get validationPasswordMin8;

  /// No description provided for @validationPasswordComplexity.
  ///
  /// In en, this message translates to:
  /// **'Password must meet complexity requirements.'**
  String get validationPasswordComplexity;

  /// No description provided for @validationPasswordUnchanged.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t made any changes.'**
  String get validationPasswordUnchanged;

  /// No description provided for @validationPasswordRules.
  ///
  /// In en, this message translates to:
  /// **'The password must be at least 8 characters long, including an uppercase letter, a lowercase letter, a number, and a special character.'**
  String get validationPasswordRules;

  /// No description provided for @validationElementIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Element ID cannot be null.'**
  String get validationElementIdRequired;

  /// No description provided for @validationRatingRequired.
  ///
  /// In en, this message translates to:
  /// **'Rating is required.'**
  String get validationRatingRequired;

  /// No description provided for @validationRatingMin1.
  ///
  /// In en, this message translates to:
  /// **'Rating must be at least 1.'**
  String get validationRatingMin1;

  /// No description provided for @validationRatingMax5.
  ///
  /// In en, this message translates to:
  /// **'Rating must be 5 or less.'**
  String get validationRatingMax5;

  /// No description provided for @validationReviewMax2000.
  ///
  /// In en, this message translates to:
  /// **'Review cannot exceed 2000 characters.'**
  String get validationReviewMax2000;

  /// No description provided for @validationTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required.'**
  String get validationTitleRequired;

  /// No description provided for @validationDescRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required.'**
  String get validationDescRequired;

  /// No description provided for @validationTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Type is required.'**
  String get validationTypeRequired;

  /// No description provided for @validationGenresRequired.
  ///
  /// In en, this message translates to:
  /// **'Genres are required.'**
  String get validationGenresRequired;

  /// No description provided for @validationGoogleTokenRequired.
  ///
  /// In en, this message translates to:
  /// **'Google token cannot be empty.'**
  String get validationGoogleTokenRequired;

  /// No description provided for @validationModStatusRequired.
  ///
  /// In en, this message translates to:
  /// **'Moderator status must be specified.'**
  String get validationModStatusRequired;

  /// No description provided for @validationAdminStatusRequired.
  ///
  /// In en, this message translates to:
  /// **'Admin status must be specified.'**
  String get validationAdminStatusRequired;

  /// No description provided for @validationSeasonMin1.
  ///
  /// In en, this message translates to:
  /// **'Season must be at least 1.'**
  String get validationSeasonMin1;

  /// No description provided for @validationUnitMin0.
  ///
  /// In en, this message translates to:
  /// **'Unit must be at least 0.'**
  String get validationUnitMin0;

  /// No description provided for @validationChapterMin0.
  ///
  /// In en, this message translates to:
  /// **'Chapter must be at least 0.'**
  String get validationChapterMin0;

  /// No description provided for @validationPageMin0.
  ///
  /// In en, this message translates to:
  /// **'Page must be at least 0.'**
  String get validationPageMin0;

  /// No description provided for @validationTypeNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Type name is required.'**
  String get validationTypeNameRequired;

  /// No description provided for @validationTypeNameMax50.
  ///
  /// In en, this message translates to:
  /// **'Type name must be 50 characters or less.'**
  String get validationTypeNameMax50;

  /// No description provided for @validationGenreNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Genre name is required.'**
  String get validationGenreNameRequired;

  /// No description provided for @validationGenreNameMax50.
  ///
  /// In en, this message translates to:
  /// **'Genre name must be 50 characters or less.'**
  String get validationGenreNameMax50;

  /// No description provided for @validationTitleMax255.
  ///
  /// In en, this message translates to:
  /// **'Title must be 255 characters or less.'**
  String get validationTitleMax255;

  /// No description provided for @validationDescMax5000.
  ///
  /// In en, this message translates to:
  /// **'Description must be 5000 characters or less.'**
  String get validationDescMax5000;

  /// No description provided for @validationEpisodesStringMax255.
  ///
  /// In en, this message translates to:
  /// **'Episodes string is too long.'**
  String get validationEpisodesStringMax255;

  /// No description provided for @validationUnitsMin1.
  ///
  /// In en, this message translates to:
  /// **'Total units must be at least 1.'**
  String get validationUnitsMin1;

  /// No description provided for @validationChaptersMin1.
  ///
  /// In en, this message translates to:
  /// **'Total chapters must be at least 1.'**
  String get validationChaptersMin1;

  /// No description provided for @validationPagesMin1.
  ///
  /// In en, this message translates to:
  /// **'Total pages must be at least 1.'**
  String get validationPagesMin1;

  /// No description provided for @validationCommentMax500.
  ///
  /// In en, this message translates to:
  /// **'Comment must be 500 characters or less.'**
  String get validationCommentMax500;

  /// No description provided for @errorEmailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Email is already registered.'**
  String get errorEmailAlreadyRegistered;

  /// No description provided for @errorUsernameAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Username already exists.'**
  String get errorUsernameAlreadyExists;

  /// No description provided for @errorPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get errorPasswordIncorrect;

  /// No description provided for @errorAlreadyReviewed.
  ///
  /// In en, this message translates to:
  /// **'You have already reviewed this item.'**
  String get errorAlreadyReviewed;

  /// No description provided for @errorInvalidRatingRange.
  ///
  /// In en, this message translates to:
  /// **'Rating must be between 1 and 5.'**
  String get errorInvalidRatingRange;

  /// No description provided for @errorProposalAlreadyHandled.
  ///
  /// In en, this message translates to:
  /// **'This proposal has already been handled.'**
  String get errorProposalAlreadyHandled;

  /// No description provided for @errorTypeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Type cannot be empty.'**
  String get errorTypeEmpty;

  /// No description provided for @errorGenresEmpty.
  ///
  /// In en, this message translates to:
  /// **'Genres cannot be empty.'**
  String get errorGenresEmpty;

  /// No description provided for @errorGenreInvalid.
  ///
  /// In en, this message translates to:
  /// **'At least one valid genre must be provided.'**
  String get errorGenreInvalid;

  /// No description provided for @errorFileEmpty.
  ///
  /// In en, this message translates to:
  /// **'File is empty.'**
  String get errorFileEmpty;

  /// No description provided for @errorAlreadyInCatalog.
  ///
  /// In en, this message translates to:
  /// **'This item is already in your catalog.'**
  String get errorAlreadyInCatalog;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Validation error.'**
  String get errorValidation;

  /// No description provided for @errorIllegalArgument.
  ///
  /// In en, this message translates to:
  /// **'Illegal argument.'**
  String get errorIllegalArgument;

  /// No description provided for @errorInternalServerError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again later.'**
  String get errorInternalServerError;

  /// No description provided for @errorAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access this resource.'**
  String get errorAccessDenied;

  /// No description provided for @errorTokenExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get errorTokenExpired;

  /// No description provided for @errorTokenInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid token. Please log in again.'**
  String get errorTokenInvalid;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorGoogleTokenInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid Google Token.'**
  String get errorGoogleTokenInvalid;

  /// No description provided for @errorGoogleTokenError.
  ///
  /// In en, this message translates to:
  /// **'Error verifying Google Token.'**
  String get errorGoogleTokenError;

  /// No description provided for @errorRefreshTokenRequired.
  ///
  /// In en, this message translates to:
  /// **'Refresh token is required.'**
  String get errorRefreshTokenRequired;

  /// No description provided for @errorRefreshTokenNotFound.
  ///
  /// In en, this message translates to:
  /// **'Refresh token not found.'**
  String get errorRefreshTokenNotFound;

  /// No description provided for @errorRefreshTokenExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get errorRefreshTokenExpired;

  /// No description provided for @errorProposalNotFound.
  ///
  /// In en, this message translates to:
  /// **'Proposal not found.'**
  String get errorProposalNotFound;

  /// No description provided for @errorNotInCatalog.
  ///
  /// In en, this message translates to:
  /// **'This item is not in your catalog.'**
  String get errorNotInCatalog;

  /// No description provided for @errorReviewerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Reviewer not found.'**
  String get errorReviewerNotFound;

  /// No description provided for @errorFileSave.
  ///
  /// In en, this message translates to:
  /// **'Error saving file.'**
  String get errorFileSave;

  /// No description provided for @errorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get errorUserNotFound;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String errorUnexpected(String error);

  /// No description provided for @errorLoadingFilters.
  ///
  /// In en, this message translates to:
  /// **'Error loading filters: {error}'**
  String errorLoadingFilters(String error);

  /// No description provided for @errorLoadingElement.
  ///
  /// In en, this message translates to:
  /// **'Error loading element:\n{error}'**
  String errorLoadingElement(String error);

  /// No description provided for @errorLoadingElements.
  ///
  /// In en, this message translates to:
  /// **'Error loading elements: {error}'**
  String errorLoadingElements(String error);

  /// No description provided for @errorLoadingReviews.
  ///
  /// In en, this message translates to:
  /// **'Error loading reviews: {error}'**
  String errorLoadingReviews(String error);

  /// No description provided for @errorLoadingProposals.
  ///
  /// In en, this message translates to:
  /// **'Error loading:\n{error}'**
  String errorLoadingProposals(String error);

  /// No description provided for @errorLoadingUsers.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorLoadingUsers(String error);

  /// No description provided for @errorLoadingCatalog.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorLoadingCatalog(String error);

  /// No description provided for @errorImagePick.
  ///
  /// In en, this message translates to:
  /// **'Error selecting image: {error}'**
  String errorImagePick(String error);

  /// No description provided for @errorImageUpload.
  ///
  /// In en, this message translates to:
  /// **'Error uploading image: {error}'**
  String errorImageUpload(String error);

  /// No description provided for @errorSaving.
  ///
  /// In en, this message translates to:
  /// **'Error saving: {error}'**
  String errorSaving(String error);

  /// No description provided for @errorUpdating.
  ///
  /// In en, this message translates to:
  /// **'Error updating: {error}'**
  String errorUpdating(String error);

  /// No description provided for @errorApproving.
  ///
  /// In en, this message translates to:
  /// **'Error approving: {error}'**
  String errorApproving(String error);

  /// No description provided for @errorUpdatingRoles.
  ///
  /// In en, this message translates to:
  /// **'Error updating roles: {error}'**
  String errorUpdatingRoles(String error);

  /// No description provided for @typeAnime.
  ///
  /// In en, this message translates to:
  /// **'Anime'**
  String get typeAnime;

  /// No description provided for @typeMovie.
  ///
  /// In en, this message translates to:
  /// **'Movie'**
  String get typeMovie;

  /// No description provided for @typeVideoGame.
  ///
  /// In en, this message translates to:
  /// **'Video Game'**
  String get typeVideoGame;

  /// No description provided for @typeManga.
  ///
  /// In en, this message translates to:
  /// **'Manga'**
  String get typeManga;

  /// No description provided for @typeManhwa.
  ///
  /// In en, this message translates to:
  /// **'Manhwa'**
  String get typeManhwa;

  /// No description provided for @typeBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get typeBook;

  /// No description provided for @typeSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get typeSeries;

  /// No description provided for @genreAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get genreAction;

  /// No description provided for @genreAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get genreAdventure;

  /// No description provided for @genreComedy.
  ///
  /// In en, this message translates to:
  /// **'Comedy'**
  String get genreComedy;

  /// No description provided for @genreDrama.
  ///
  /// In en, this message translates to:
  /// **'Drama'**
  String get genreDrama;

  /// No description provided for @genreFantasy.
  ///
  /// In en, this message translates to:
  /// **'Fantasy'**
  String get genreFantasy;

  /// No description provided for @genreHorror.
  ///
  /// In en, this message translates to:
  /// **'Horror'**
  String get genreHorror;

  /// No description provided for @genreMystery.
  ///
  /// In en, this message translates to:
  /// **'Mystery'**
  String get genreMystery;

  /// No description provided for @genreRomance.
  ///
  /// In en, this message translates to:
  /// **'Romance'**
  String get genreRomance;

  /// No description provided for @genreSciFi.
  ///
  /// In en, this message translates to:
  /// **'Sci-Fi'**
  String get genreSciFi;

  /// No description provided for @genreSliceOfLife.
  ///
  /// In en, this message translates to:
  /// **'Slice of Life'**
  String get genreSliceOfLife;

  /// No description provided for @genrePsychological.
  ///
  /// In en, this message translates to:
  /// **'Psychological'**
  String get genrePsychological;

  /// No description provided for @genreThriller.
  ///
  /// In en, this message translates to:
  /// **'Thriller'**
  String get genreThriller;

  /// No description provided for @genreHistorical.
  ///
  /// In en, this message translates to:
  /// **'Historical'**
  String get genreHistorical;

  /// No description provided for @genreCrime.
  ///
  /// In en, this message translates to:
  /// **'Crime'**
  String get genreCrime;

  /// No description provided for @genreFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get genreFamily;

  /// No description provided for @genreWar.
  ///
  /// In en, this message translates to:
  /// **'War'**
  String get genreWar;

  /// No description provided for @genreCyberpunk.
  ///
  /// In en, this message translates to:
  /// **'Cyberpunk'**
  String get genreCyberpunk;

  /// No description provided for @genrePostApocalyptic.
  ///
  /// In en, this message translates to:
  /// **'Post-Apocalyptic'**
  String get genrePostApocalyptic;

  /// No description provided for @genreShonen.
  ///
  /// In en, this message translates to:
  /// **'Shonen'**
  String get genreShonen;

  /// No description provided for @genreShojo.
  ///
  /// In en, this message translates to:
  /// **'Shojo'**
  String get genreShojo;

  /// No description provided for @genreSeinen.
  ///
  /// In en, this message translates to:
  /// **'Seinen'**
  String get genreSeinen;

  /// No description provided for @genreJosei.
  ///
  /// In en, this message translates to:
  /// **'Josei'**
  String get genreJosei;

  /// No description provided for @genreIsekai.
  ///
  /// In en, this message translates to:
  /// **'Isekai'**
  String get genreIsekai;

  /// No description provided for @genreMecha.
  ///
  /// In en, this message translates to:
  /// **'Mecha'**
  String get genreMecha;

  /// No description provided for @genreHarem.
  ///
  /// In en, this message translates to:
  /// **'Harem'**
  String get genreHarem;

  /// No description provided for @genreEcchi.
  ///
  /// In en, this message translates to:
  /// **'Ecchi'**
  String get genreEcchi;

  /// No description provided for @genreYaoi.
  ///
  /// In en, this message translates to:
  /// **'Yaoi'**
  String get genreYaoi;

  /// No description provided for @genreYuri.
  ///
  /// In en, this message translates to:
  /// **'Yuri'**
  String get genreYuri;

  /// No description provided for @genreMartialArts.
  ///
  /// In en, this message translates to:
  /// **'Martial Arts'**
  String get genreMartialArts;

  /// No description provided for @genreSchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get genreSchool;

  /// No description provided for @genreRPG.
  ///
  /// In en, this message translates to:
  /// **'RPG'**
  String get genreRPG;

  /// No description provided for @genreShooter.
  ///
  /// In en, this message translates to:
  /// **'Shooter'**
  String get genreShooter;

  /// No description provided for @genrePlatformer.
  ///
  /// In en, this message translates to:
  /// **'Platformer'**
  String get genrePlatformer;

  /// No description provided for @genreStrategy.
  ///
  /// In en, this message translates to:
  /// **'Strategy'**
  String get genreStrategy;

  /// No description provided for @genrePuzzle.
  ///
  /// In en, this message translates to:
  /// **'Puzzle'**
  String get genrePuzzle;

  /// No description provided for @genreFighting.
  ///
  /// In en, this message translates to:
  /// **'Fighting'**
  String get genreFighting;

  /// No description provided for @genreSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get genreSports;

  /// No description provided for @genreRacing.
  ///
  /// In en, this message translates to:
  /// **'Racing'**
  String get genreRacing;

  /// No description provided for @genreOpenWorld.
  ///
  /// In en, this message translates to:
  /// **'Open World'**
  String get genreOpenWorld;

  /// No description provided for @genreRoguelike.
  ///
  /// In en, this message translates to:
  /// **'Roguelike'**
  String get genreRoguelike;

  /// No description provided for @genreMOBA.
  ///
  /// In en, this message translates to:
  /// **'MOBA'**
  String get genreMOBA;

  /// No description provided for @genreBattleRoyale.
  ///
  /// In en, this message translates to:
  /// **'Battle Royale'**
  String get genreBattleRoyale;

  /// No description provided for @genreSimulator.
  ///
  /// In en, this message translates to:
  /// **'Simulator'**
  String get genreSimulator;

  /// No description provided for @genreSurvivalHorror.
  ///
  /// In en, this message translates to:
  /// **'Survival Horror'**
  String get genreSurvivalHorror;

  /// No description provided for @genreBiography.
  ///
  /// In en, this message translates to:
  /// **'Biography'**
  String get genreBiography;

  /// No description provided for @genreEssay.
  ///
  /// In en, this message translates to:
  /// **'Essay'**
  String get genreEssay;

  /// No description provided for @genrePoetry.
  ///
  /// In en, this message translates to:
  /// **'Poetry'**
  String get genrePoetry;

  /// No description provided for @genreSelfHelp.
  ///
  /// In en, this message translates to:
  /// **'Self-Help'**
  String get genreSelfHelp;

  /// No description provided for @genreBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get genreBusiness;

  /// No description provided for @genreNoir.
  ///
  /// In en, this message translates to:
  /// **'Noir'**
  String get genreNoir;

  /// No description provided for @genreMagicalRealism.
  ///
  /// In en, this message translates to:
  /// **'Magical Realism'**
  String get genreMagicalRealism;
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
