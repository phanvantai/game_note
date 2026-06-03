import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('vi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'PES Arena'**
  String get appName;

  /// No description provided for @mainTabArena.
  ///
  /// In en, this message translates to:
  /// **'Arena'**
  String get mainTabArena;

  /// No description provided for @mainTabGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get mainTabGroups;

  /// No description provided for @mainTabTournaments.
  ///
  /// In en, this message translates to:
  /// **'Tournaments'**
  String get mainTabTournaments;

  /// No description provided for @mainTabNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get mainTabNotifications;

  /// No description provided for @mainTabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get mainTabProfile;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in settings.'**
  String get languageSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVietnamese;

  /// No description provided for @languageSystemMatch.
  ///
  /// In en, this message translates to:
  /// **'Suggested from your device'**
  String get languageSystemMatch;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsHeroEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsHeroEyebrow;

  /// No description provided for @settingsHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Security, appearance, and account.'**
  String get settingsHeroSubtitle;

  /// No description provided for @settingsUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update profile'**
  String get settingsUpdateProfile;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get settingsDeleteConfirmTitle;

  /// No description provided for @settingsDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?\n\nAll of your personal data will be deleted and cannot be restored. Some data related to groups and other players will be kept.'**
  String get settingsDeleteConfirmMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ownershipCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check ownership: {error}'**
  String ownershipCheckFailed(String error);

  /// No description provided for @authContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get authContinue;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegister;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get authForgotPassword;

  /// No description provided for @authResetPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send reset email'**
  String get authResetPasswordSubmit;

  /// No description provided for @authResetPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent'**
  String get authResetPasswordSent;

  /// No description provided for @authSignInSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully'**
  String get authSignInSuccess;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailHint;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordHint;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authContinueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueWithApple;

  /// No description provided for @authVerifyAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify account'**
  String get authVerifyAccountTitle;

  /// No description provided for @authVerificationSent.
  ///
  /// In en, this message translates to:
  /// **'A verification code has been sent to your phone number'**
  String get authVerificationSent;

  /// No description provided for @authVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get authVerificationCode;

  /// No description provided for @authVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authVerify;

  /// No description provided for @profileChangePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profileChangePasswordTitle;

  /// No description provided for @profileCurrentPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get profileCurrentPasswordHint;

  /// No description provided for @profileNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get profileNewPasswordHint;

  /// No description provided for @profileConfirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get profileConfirmNewPasswordHint;

  /// No description provided for @profileChangePasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get profileChangePasswordSuccess;

  /// No description provided for @profileSecurityEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get profileSecurityEyebrow;

  /// No description provided for @profileSecuritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your password to protect your account.'**
  String get profileSecuritySubtitle;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'Or'**
  String get or;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @backHome.
  ///
  /// In en, this message translates to:
  /// **'Back home'**
  String get backHome;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get commonSend;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get commonUpdate;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get commonUnknown;

  /// No description provided for @commonErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonErrorTitle;

  /// No description provided for @commonRetryLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get commonRetryLater;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonSearchByName.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get commonSearchByName;

  /// No description provided for @appOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get appOnline;

  /// No description provided for @appOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get appOffline;

  /// No description provided for @offlineLeagueTitle.
  ///
  /// In en, this message translates to:
  /// **'Tournaments'**
  String get offlineLeagueTitle;

  /// No description provided for @offlinePlayersTitle.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get offlinePlayersTitle;

  /// No description provided for @offlineStatisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get offlineStatisticsTitle;

  /// No description provided for @offlineCreateLeagueTitle.
  ///
  /// In en, this message translates to:
  /// **'Create tournament'**
  String get offlineCreateLeagueTitle;

  /// No description provided for @offlineLeagueNameHint.
  ///
  /// In en, this message translates to:
  /// **'Tournament name'**
  String get offlineLeagueNameHint;

  /// No description provided for @offlineAddLeagueTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add new tournament'**
  String get offlineAddLeagueTooltip;

  /// No description provided for @offlineNoLeaguesTitle.
  ///
  /// In en, this message translates to:
  /// **'No tournaments have been created.'**
  String get offlineNoLeaguesTitle;

  /// No description provided for @offlineNoLeaguesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button below to create a tournament'**
  String get offlineNoLeaguesSubtitle;

  /// No description provided for @offlineDeleteLeagueTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete tournament'**
  String get offlineDeleteLeagueTitle;

  /// No description provided for @offlineDeleteLeagueMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete tournament {name}?'**
  String offlineDeleteLeagueMessage(String name);

  /// No description provided for @offlineShareStandingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Standings - {name}'**
  String offlineShareStandingsTitle(String name);

  /// No description provided for @offlineLeagueNotSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Tournament is not set up.'**
  String get offlineLeagueNotSetupTitle;

  /// No description provided for @offlineLeagueNotSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button below to add players and start the tournament'**
  String get offlineLeagueNotSetupSubtitle;

  /// No description provided for @offlineLoadLeagueFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load tournament data'**
  String get offlineLoadLeagueFailed;

  /// No description provided for @offlineShareStandings.
  ///
  /// In en, this message translates to:
  /// **'Share standings'**
  String get offlineShareStandings;

  /// No description provided for @offlineSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get offlineSchedule;

  /// No description provided for @offlineResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get offlineResults;

  /// No description provided for @offlineAddPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add player'**
  String get offlineAddPlayerTitle;

  /// No description provided for @offlinePlayerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Player name'**
  String get offlinePlayerNameHint;

  /// No description provided for @offlineNoPlayersTitle.
  ///
  /// In en, this message translates to:
  /// **'No players yet.'**
  String get offlineNoPlayersTitle;

  /// No description provided for @offlineNoPlayersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button below to add a player.'**
  String get offlineNoPlayersSubtitle;

  /// No description provided for @offlineAddPlayerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add player'**
  String get offlineAddPlayerTooltip;

  /// No description provided for @offlinePlayerDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name}'**
  String offlinePlayerDeleted(String name);

  /// No description provided for @offlineUpdateScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Update score'**
  String get offlineUpdateScoreTitle;

  /// No description provided for @offlineAddRoundTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add round'**
  String get offlineAddRoundTooltip;

  /// No description provided for @offlineSelectingPlayers.
  ///
  /// In en, this message translates to:
  /// **'Selecting 2 players. Selected: {count}'**
  String offlineSelectingPlayers(int count);

  /// No description provided for @offlineSelectedPlayers.
  ///
  /// In en, this message translates to:
  /// **'Selected: {count}'**
  String offlineSelectedPlayers(int count);

  /// No description provided for @offlineDataTitle.
  ///
  /// In en, this message translates to:
  /// **'DATA'**
  String get offlineDataTitle;

  /// No description provided for @offlineImportData.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get offlineImportData;

  /// No description provided for @offlineExportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get offlineExportData;

  /// No description provided for @offlineInvalidImportFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid file.\nPlease use a game_note_database.db database file'**
  String get offlineInvalidImportFile;

  /// No description provided for @offlineImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data imported successfully'**
  String get offlineImportSuccess;

  /// No description provided for @offlineStatPointsGoalDiff.
  ///
  /// In en, this message translates to:
  /// **'Points/GD'**
  String get offlineStatPointsGoalDiff;

  /// No description provided for @offlineStatChampionRunnerUp.
  ///
  /// In en, this message translates to:
  /// **'Champion/Runner-up'**
  String get offlineStatChampionRunnerUp;

  /// No description provided for @offlineStatWinDrawLoss.
  ///
  /// In en, this message translates to:
  /// **'Win/Draw/Loss'**
  String get offlineStatWinDrawLoss;

  /// No description provided for @syncNoOfflineLeague.
  ///
  /// In en, this message translates to:
  /// **'No offline league available to sync'**
  String get syncNoOfflineLeague;

  /// No description provided for @syncNoGroup.
  ///
  /// In en, this message translates to:
  /// **'You have not joined any group'**
  String get syncNoGroup;

  /// No description provided for @syncNoLeagueSelected.
  ///
  /// In en, this message translates to:
  /// **'No league selected'**
  String get syncNoLeagueSelected;

  /// No description provided for @syncChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get syncChoose;

  /// No description provided for @syncNoGroupMembers.
  ///
  /// In en, this message translates to:
  /// **'Group has no members'**
  String get syncNoGroupMembers;

  /// No description provided for @syncCreatePlaceholderUser.
  ///
  /// In en, this message translates to:
  /// **'Create new user (placeholder)'**
  String get syncCreatePlaceholderUser;

  /// No description provided for @syncNewPlayerName.
  ///
  /// In en, this message translates to:
  /// **'New player name'**
  String get syncNewPlayerName;

  /// No description provided for @syncDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get syncDisplayNameHint;

  /// No description provided for @syncMissingData.
  ///
  /// In en, this message translates to:
  /// **'Missing data'**
  String get syncMissingData;

  /// No description provided for @syncDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String syncDateLabel(String date);

  /// No description provided for @syncTargetGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Target group: {group}'**
  String syncTargetGroupLabel(String group);

  /// No description provided for @syncNoPlayedMatches.
  ///
  /// In en, this message translates to:
  /// **'No played matches'**
  String get syncNoPlayedMatches;

  /// No description provided for @syncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sync completed'**
  String get syncSuccess;

  /// No description provided for @syncRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get syncRetry;

  /// No description provided for @syncBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get syncBack;

  /// No description provided for @syncExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get syncExit;

  /// No description provided for @syncContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get syncContinue;

  /// No description provided for @syncOfflineLeagueSection.
  ///
  /// In en, this message translates to:
  /// **'Offline league'**
  String get syncOfflineLeagueSection;

  /// No description provided for @syncOnlineGroupSection.
  ///
  /// In en, this message translates to:
  /// **'Online group'**
  String get syncOnlineGroupSection;

  /// No description provided for @syncLeagueDescription.
  ///
  /// In en, this message translates to:
  /// **'{players} players · {date}'**
  String syncLeagueDescription(int players, String date);

  /// No description provided for @syncPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get syncPreview;

  /// No description provided for @syncDuplicateMapping.
  ///
  /// In en, this message translates to:
  /// **'Error: 2 players map to the same user'**
  String get syncDuplicateMapping;

  /// No description provided for @syncNotMapped.
  ///
  /// In en, this message translates to:
  /// **'Not mapped'**
  String get syncNotMapped;

  /// No description provided for @syncNewTargetSuffix.
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get syncNewTargetSuffix;

  /// No description provided for @syncMapPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Map \"{name}\"'**
  String syncMapPlayerTitle(String name);

  /// No description provided for @syncWritingData.
  ///
  /// In en, this message translates to:
  /// **'Writing data to server...'**
  String get syncWritingData;

  /// No description provided for @syncDoNotClose.
  ///
  /// In en, this message translates to:
  /// **'Please do not close the app until it is complete'**
  String get syncDoNotClose;

  /// No description provided for @syncSelectSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose league & group'**
  String get syncSelectSourceTitle;

  /// No description provided for @syncMapPlayersTitle.
  ///
  /// In en, this message translates to:
  /// **'Map players'**
  String get syncMapPlayersTitle;

  /// No description provided for @syncConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get syncConfirmTitle;

  /// No description provided for @syncExecutingTitle.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get syncExecutingTitle;

  /// No description provided for @syncOriginalOfflineTab.
  ///
  /// In en, this message translates to:
  /// **'Offline (original)'**
  String get syncOriginalOfflineTab;

  /// No description provided for @syncOnlineWillCreateTab.
  ///
  /// In en, this message translates to:
  /// **'Online (will create)'**
  String get syncOnlineWillCreateTab;

  /// No description provided for @syncRun.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncRun;

  /// No description provided for @syncNewSuffix.
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get syncNewSuffix;

  /// No description provided for @syncWritesCount.
  ///
  /// In en, this message translates to:
  /// **'Will write {count} records to server'**
  String syncWritesCount(int count);

  /// No description provided for @syncStandingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Standings'**
  String get syncStandingsTitle;

  /// No description provided for @syncMatchResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Match results ({count})'**
  String syncMatchResultsTitle(int count);

  /// No description provided for @syncNewPlayersWillBeCreated.
  ///
  /// In en, this message translates to:
  /// **'New players will be created ({count})'**
  String syncNewPlayersWillBeCreated(int count);

  /// No description provided for @tablePlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get tablePlayer;

  /// No description provided for @tableMatchesPlayedShort.
  ///
  /// In en, this message translates to:
  /// **'MP'**
  String get tableMatchesPlayedShort;

  /// No description provided for @tableWinsShort.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get tableWinsShort;

  /// No description provided for @tableDrawsShort.
  ///
  /// In en, this message translates to:
  /// **'D'**
  String get tableDrawsShort;

  /// No description provided for @tableLossesShort.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get tableLossesShort;

  /// No description provided for @tableGoalsForShort.
  ///
  /// In en, this message translates to:
  /// **'GF'**
  String get tableGoalsForShort;

  /// No description provided for @tableGoalsAgainstShort.
  ///
  /// In en, this message translates to:
  /// **'GA'**
  String get tableGoalsAgainstShort;

  /// No description provided for @tableGoalDifferenceShort.
  ///
  /// In en, this message translates to:
  /// **'GD'**
  String get tableGoalDifferenceShort;

  /// No description provided for @tablePointsShort.
  ///
  /// In en, this message translates to:
  /// **'Pts'**
  String get tablePointsShort;

  /// No description provided for @groupCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Group created successfully'**
  String get groupCreateSuccess;

  /// No description provided for @groupCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create new group'**
  String get groupCreateTitle;

  /// No description provided for @groupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupNameHint;

  /// No description provided for @groupDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Group description'**
  String get groupDescriptionHint;

  /// No description provided for @groupNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Group name cannot be empty'**
  String get groupNameRequired;

  /// No description provided for @groupCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get groupCreateButton;

  /// No description provided for @groupEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No groups'**
  String get groupEmptyTitle;

  /// No description provided for @groupEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new group to get started'**
  String get groupEmptySubtitle;

  /// No description provided for @groupHeroEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Community hub'**
  String get groupHeroEyebrow;

  /// No description provided for @groupHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage PES groups'**
  String get groupHeroTitle;

  /// No description provided for @groupCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get groupCreateNew;

  /// No description provided for @groupMineStat.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get groupMineStat;

  /// No description provided for @groupDiscoverStat.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get groupDiscoverStat;

  /// No description provided for @groupMembersStat.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get groupMembersStat;

  /// No description provided for @groupMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String groupMemberCount(int count);

  /// No description provided for @groupMyGroupsTab.
  ///
  /// In en, this message translates to:
  /// **'My groups'**
  String get groupMyGroupsTab;

  /// No description provided for @groupOtherGroupsTab.
  ///
  /// In en, this message translates to:
  /// **'Other groups'**
  String get groupOtherGroupsTab;

  /// No description provided for @groupAddMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get groupAddMemberTitle;

  /// No description provided for @groupCreatePlaceholderPlayer.
  ///
  /// In en, this message translates to:
  /// **'Create new player (placeholder)'**
  String get groupCreatePlaceholderPlayer;

  /// No description provided for @groupCreateNewPlayer.
  ///
  /// In en, this message translates to:
  /// **'Create new player'**
  String get groupCreateNewPlayer;

  /// No description provided for @groupDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the group, all tournaments, matches, standings, and related stats. Data cannot be restored.'**
  String get groupDeleteWarning;

  /// No description provided for @groupSearchByNameHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get groupSearchByNameHint;

  /// No description provided for @groupPlayerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Player name'**
  String get groupPlayerNameHint;

  /// No description provided for @groupAddMemberSuccess.
  ///
  /// In en, this message translates to:
  /// **'Member added successfully'**
  String get groupAddMemberSuccess;

  /// No description provided for @groupPlayerAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'New player added'**
  String get groupPlayerAddedSuccess;

  /// No description provided for @groupUpdateStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update status'**
  String get groupUpdateStatusFailed;

  /// No description provided for @groupDeleteRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Group deletion request sent'**
  String get groupDeleteRequestSent;

  /// No description provided for @groupDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get groupDeleteTitle;

  /// No description provided for @groupOverviewTab.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get groupOverviewTab;

  /// No description provided for @groupMembersTab.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get groupMembersTab;

  /// No description provided for @groupInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get groupInactive;

  /// No description provided for @groupDescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get groupDescriptionTitle;

  /// No description provided for @groupNoOverview.
  ///
  /// In en, this message translates to:
  /// **'No overview data yet'**
  String get groupNoOverview;

  /// No description provided for @groupRefreshStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Update stats?'**
  String get groupRefreshStatsTitle;

  /// No description provided for @groupRefreshStatsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Update stats'**
  String get groupRefreshStatsTooltip;

  /// No description provided for @groupOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Group overview'**
  String get groupOverviewTitle;

  /// No description provided for @groupYearFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get groupYearFilterAll;

  /// No description provided for @groupRefreshStatsMessage.
  ///
  /// In en, this message translates to:
  /// **'The system will reload all tournaments and recalculate group stats. This may take a few seconds.'**
  String get groupRefreshStatsMessage;

  /// No description provided for @groupOverviewLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load overview data.'**
  String get groupOverviewLoadFailed;

  /// No description provided for @groupOverviewLoadError.
  ///
  /// In en, this message translates to:
  /// **'Overview load error: {message}'**
  String groupOverviewLoadError(String message);

  /// No description provided for @groupLegendChampion.
  ///
  /// In en, this message translates to:
  /// **'Unbeatable'**
  String get groupLegendChampion;

  /// No description provided for @groupLegendRunnerUp.
  ///
  /// In en, this message translates to:
  /// **'Great runner-up'**
  String get groupLegendRunnerUp;

  /// No description provided for @groupLegendPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get groupLegendPro;

  /// No description provided for @groupLegendDefense.
  ///
  /// In en, this message translates to:
  /// **'Steel defense'**
  String get groupLegendDefense;

  /// No description provided for @groupTitles.
  ///
  /// In en, this message translates to:
  /// **'Titles'**
  String get groupTitles;

  /// No description provided for @groupMemberStats.
  ///
  /// In en, this message translates to:
  /// **'Member stats'**
  String get groupMemberStats;

  /// No description provided for @groupNotEnoughAwardsData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data to award titles (requires at least 5 finished tournaments or 5 matches).'**
  String get groupNotEnoughAwardsData;

  /// No description provided for @groupNoMemberStats.
  ///
  /// In en, this message translates to:
  /// **'No member data yet.'**
  String get groupNoMemberStats;

  /// No description provided for @groupReplaceSuccess.
  ///
  /// In en, this message translates to:
  /// **'Replaced successfully'**
  String get groupReplaceSuccess;

  /// No description provided for @groupReplaceError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong, please try again'**
  String get groupReplaceError;

  /// No description provided for @groupReplaceSelectOld.
  ///
  /// In en, this message translates to:
  /// **'Choose player to replace'**
  String get groupReplaceSelectOld;

  /// No description provided for @groupReplaceSelectNew.
  ///
  /// In en, this message translates to:
  /// **'Choose replacement'**
  String get groupReplaceSelectNew;

  /// No description provided for @groupReplaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm replacement'**
  String get groupReplaceConfirm;

  /// No description provided for @groupNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get groupNoSearchResults;

  /// No description provided for @groupReplaceOldLabel.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get groupReplaceOldLabel;

  /// No description provided for @groupReplaceNewLabel.
  ///
  /// In en, this message translates to:
  /// **'With'**
  String get groupReplaceNewLabel;

  /// No description provided for @groupReplaceMergeWarning.
  ///
  /// In en, this message translates to:
  /// **'This player is already in the tournament. Stats for both players will be merged.'**
  String get groupReplaceMergeWarning;

  /// No description provided for @groupActionIrreversible.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get groupActionIrreversible;

  /// No description provided for @groupClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get groupClose;

  /// No description provided for @groupPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Placeholder'**
  String get groupPlaceholder;

  /// No description provided for @costRankPayoutRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter rank payout amounts (for example: 50, 100)'**
  String get costRankPayoutRequired;

  /// No description provided for @costBracketPayoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Calculate by bracket'**
  String get costBracketPayoutTitle;

  /// No description provided for @costRankPayoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Calculate by rank'**
  String get costRankPayoutTitle;

  /// No description provided for @costBracketPayoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Champion receives money from runner-up and earlier eliminated players'**
  String get costBracketPayoutSubtitle;

  /// No description provided for @costRankPayoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lower ranks contribute to first place using this configuration'**
  String get costRankPayoutSubtitle;

  /// No description provided for @costPayoutHint.
  ///
  /// In en, this message translates to:
  /// **'Example: 50, 100, 150 (k VND)'**
  String get costPayoutHint;

  /// No description provided for @costBracketPayoutOrder.
  ///
  /// In en, this message translates to:
  /// **'In order: runner-up, each semifinal loser, each quarterfinal loser...'**
  String get costBracketPayoutOrder;

  /// No description provided for @costRankPayoutOrder.
  ///
  /// In en, this message translates to:
  /// **'In order: rank 2, rank 3, rank 4... pay rank 1.'**
  String get costRankPayoutOrder;

  /// No description provided for @costDefaultMatchCostHint.
  ///
  /// In en, this message translates to:
  /// **'Default amount per match (k VND)'**
  String get costDefaultMatchCostHint;

  /// No description provided for @costDefaultMatchCostHelp.
  ///
  /// In en, this message translates to:
  /// **'This amount is prefilled when cost is enabled for a match while entering the result.'**
  String get costDefaultMatchCostHelp;

  /// No description provided for @costDefaultPerGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable goal-difference cost by default'**
  String get costDefaultPerGoalTitle;

  /// No description provided for @costDefaultPerGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Loser pays extra by goal difference (for example: 3-1 adds this amount twice).'**
  String get costDefaultPerGoalSubtitle;

  /// No description provided for @costPerGoalHint.
  ///
  /// In en, this message translates to:
  /// **'Amount per goal (k VND)'**
  String get costPerGoalHint;

  /// No description provided for @costPerGoalHelp.
  ///
  /// In en, this message translates to:
  /// **'Added to the per-match amount when that match also has cost enabled.'**
  String get costPerGoalHelp;

  /// No description provided for @costSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions:'**
  String get costSuggestions;

  /// No description provided for @costPresetAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'{amounts} k'**
  String costPresetAmountLabel(String amounts);

  /// No description provided for @tournamentSelectGroupRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a group'**
  String get tournamentSelectGroupRequired;

  /// No description provided for @tournamentParticipantsMinimum.
  ///
  /// In en, this message translates to:
  /// **'Select at least 2 participants'**
  String get tournamentParticipantsMinimum;

  /// No description provided for @tournamentCupPowerOfTwoRequired.
  ///
  /// In en, this message translates to:
  /// **'Cup requires participant count to be a power of 2 (2, 4, 8, 16...)'**
  String get tournamentCupPowerOfTwoRequired;

  /// No description provided for @tournamentFullKnockoutPowerOfTwoRequired.
  ///
  /// In en, this message translates to:
  /// **'Groups x knockout qualifiers must be a power of 2'**
  String get tournamentFullKnockoutPowerOfTwoRequired;

  /// No description provided for @tournamentNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a tournament name'**
  String get tournamentNameRequired;

  /// No description provided for @tournamentStartBeforeEndRequired.
  ///
  /// In en, this message translates to:
  /// **'Start date must be before end date'**
  String get tournamentStartBeforeEndRequired;

  /// No description provided for @tournamentEndAfterStartRequired.
  ///
  /// In en, this message translates to:
  /// **'End date must be after start date'**
  String get tournamentEndAfterStartRequired;

  /// No description provided for @tournamentNoGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'You have not joined any groups'**
  String get tournamentNoGroupsTitle;

  /// No description provided for @tournamentNoGroupsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create or join a group before creating a tournament'**
  String get tournamentNoGroupsSubtitle;

  /// No description provided for @tournamentSelectGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Select group'**
  String get tournamentSelectGroupTitle;

  /// No description provided for @tournamentSelectGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This tournament will belong to this group'**
  String get tournamentSelectGroupSubtitle;

  /// No description provided for @tournamentMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String tournamentMembersCount(int count);

  /// No description provided for @tournamentAddPlayersTitle.
  ///
  /// In en, this message translates to:
  /// **'Add players'**
  String get tournamentAddPlayersTitle;

  /// No description provided for @tournamentAddPlayersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select at least 2 players ({count} selected)'**
  String tournamentAddPlayersSubtitle(int count);

  /// No description provided for @tournamentModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Tournament mode'**
  String get tournamentModeTitle;

  /// No description provided for @tournamentModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose competition format'**
  String get tournamentModeSubtitle;

  /// No description provided for @tournamentModeLeague.
  ///
  /// In en, this message translates to:
  /// **'League'**
  String get tournamentModeLeague;

  /// No description provided for @tournamentModeLeagueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Round robin, everyone plays each other'**
  String get tournamentModeLeagueSubtitle;

  /// No description provided for @tournamentModeCup.
  ///
  /// In en, this message translates to:
  /// **'Cup'**
  String get tournamentModeCup;

  /// No description provided for @tournamentModeCupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Knockout, one loss and out'**
  String get tournamentModeCupSubtitle;

  /// No description provided for @tournamentModeFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get tournamentModeFull;

  /// No description provided for @tournamentModeFullSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Group stage to knockout'**
  String get tournamentModeFullSubtitle;

  /// No description provided for @tournamentConfigPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Configuration & Preview'**
  String get tournamentConfigPreviewTitle;

  /// No description provided for @tournamentConfigPreviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize before creating'**
  String get tournamentConfigPreviewSubtitle;

  /// No description provided for @tournamentInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Tournament info'**
  String get tournamentInfoTitle;

  /// No description provided for @tournamentInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set name and dates'**
  String get tournamentInfoSubtitle;

  /// No description provided for @tournamentNameDescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Name & description'**
  String get tournamentNameDescriptionTitle;

  /// No description provided for @tournamentNameHint.
  ///
  /// In en, this message translates to:
  /// **'Tournament name'**
  String get tournamentNameHint;

  /// No description provided for @tournamentDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get tournamentDescriptionHint;

  /// No description provided for @tournamentTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get tournamentTimeTitle;

  /// No description provided for @tournamentStartDateHint.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get tournamentStartDateHint;

  /// No description provided for @tournamentEndDateHint.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get tournamentEndDateHint;

  /// No description provided for @tournamentCostSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Can be configured later'**
  String get tournamentCostSubtitle;

  /// No description provided for @tournamentStatsSynced.
  ///
  /// In en, this message translates to:
  /// **'Scores synced'**
  String get tournamentStatsSynced;

  /// No description provided for @tournamentCostUpdated.
  ///
  /// In en, this message translates to:
  /// **'Tournament cost updated'**
  String get tournamentCostUpdated;

  /// No description provided for @tournamentCustomMatchCreated.
  ///
  /// In en, this message translates to:
  /// **'Match created successfully'**
  String get tournamentCustomMatchCreated;

  /// No description provided for @tournamentCreateMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Create match'**
  String get tournamentCreateMatchTitle;

  /// No description provided for @tournamentMatchDeleted.
  ///
  /// In en, this message translates to:
  /// **'Match deleted successfully'**
  String get tournamentMatchDeleted;

  /// No description provided for @tournamentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Tournament deleted'**
  String get tournamentDeleted;

  /// No description provided for @tournamentStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Tournament status updated successfully'**
  String get tournamentStatusUpdated;

  /// No description provided for @tournamentPlayerAdded.
  ///
  /// In en, this message translates to:
  /// **'Player added successfully'**
  String get tournamentPlayerAdded;

  /// No description provided for @tournamentPlayersAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} players added successfully'**
  String tournamentPlayersAdded(int count);

  /// No description provided for @tournamentGroupRoundMinimum.
  ///
  /// In en, this message translates to:
  /// **'Group needs at least 2 players to create a round'**
  String get tournamentGroupRoundMinimum;

  /// No description provided for @tournamentRoundCreated.
  ///
  /// In en, this message translates to:
  /// **'Round created successfully'**
  String get tournamentRoundCreated;

  /// No description provided for @tournamentMatchUpdated.
  ///
  /// In en, this message translates to:
  /// **'Match updated successfully'**
  String get tournamentMatchUpdated;

  /// No description provided for @tournamentMatchConcurrentUpdate.
  ///
  /// In en, this message translates to:
  /// **'This match was just updated by someone else. Please check again.'**
  String get tournamentMatchConcurrentUpdate;

  /// No description provided for @tournamentBracketCreated.
  ///
  /// In en, this message translates to:
  /// **'Bracket created successfully'**
  String get tournamentBracketCreated;

  /// No description provided for @tournamentFullCreated.
  ///
  /// In en, this message translates to:
  /// **'Full tournament created successfully'**
  String get tournamentFullCreated;

  /// No description provided for @tournamentSelectedPlayersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected:'**
  String tournamentSelectedPlayersCount(int count);

  /// No description provided for @tournamentAddPlayersCount.
  ///
  /// In en, this message translates to:
  /// **'Add {count} players'**
  String tournamentAddPlayersCount(int count);

  /// No description provided for @tournamentLoadingCost.
  ///
  /// In en, this message translates to:
  /// **'Loading costs'**
  String get tournamentLoadingCost;

  /// No description provided for @tournamentNoCostTitle.
  ///
  /// In en, this message translates to:
  /// **'No costs yet'**
  String get tournamentNoCostTitle;

  /// No description provided for @tournamentNoCostSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable cost configuration or enter money in each match'**
  String get tournamentNoCostSubtitle;

  /// No description provided for @tournamentHomeTeamHint.
  ///
  /// In en, this message translates to:
  /// **'Home team'**
  String get tournamentHomeTeamHint;

  /// No description provided for @tournamentAwayTeamHint.
  ///
  /// In en, this message translates to:
  /// **'Away team'**
  String get tournamentAwayTeamHint;

  /// No description provided for @tournamentSelectTeamRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select teams'**
  String get tournamentSelectTeamRequired;

  /// No description provided for @tournamentDistinctTeamsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select 2 different teams'**
  String get tournamentDistinctTeamsRequired;

  /// No description provided for @tournamentUpdateResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Update result'**
  String get tournamentUpdateResultTitle;

  /// No description provided for @tournamentMatchHasCost.
  ///
  /// In en, this message translates to:
  /// **'This match has cost'**
  String get tournamentMatchHasCost;

  /// No description provided for @tournamentMatchCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (k VND)'**
  String get tournamentMatchCostLabel;

  /// No description provided for @tournamentAddGoalDifferenceCost.
  ///
  /// In en, this message translates to:
  /// **'Add goal-difference cost'**
  String get tournamentAddGoalDifferenceCost;

  /// No description provided for @tournamentGoalDifferenceCostHelp.
  ///
  /// In en, this message translates to:
  /// **'For example: 3-1 adds this amount twice.'**
  String get tournamentGoalDifferenceCostHelp;

  /// No description provided for @tournamentScoreRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter match result'**
  String get tournamentScoreRequired;

  /// No description provided for @tournamentTabBracket.
  ///
  /// In en, this message translates to:
  /// **'Bracket'**
  String get tournamentTabBracket;

  /// No description provided for @tournamentTabResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get tournamentTabResults;

  /// No description provided for @tournamentTabCost.
  ///
  /// In en, this message translates to:
  /// **'Costs'**
  String get tournamentTabCost;

  /// No description provided for @tournamentTabGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get tournamentTabGroups;

  /// No description provided for @tournamentGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group {groupId}'**
  String tournamentGroupLabel(String groupId);

  /// No description provided for @tournamentTabStandings.
  ///
  /// In en, this message translates to:
  /// **'Standings'**
  String get tournamentTabStandings;

  /// No description provided for @tournamentTabFixtures.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get tournamentTabFixtures;

  /// No description provided for @tournamentStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Tournament status'**
  String get tournamentStatusTitle;

  /// No description provided for @tournamentRecomputeStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync scores'**
  String get tournamentRecomputeStatsTitle;

  /// No description provided for @tournamentRecomputeStatsMessage.
  ///
  /// In en, this message translates to:
  /// **'Recalculate all scores from finished match results? Use this when scores are inconsistent due to old data.'**
  String get tournamentRecomputeStatsMessage;

  /// No description provided for @tournamentRecomputeStatsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get tournamentRecomputeStatsConfirm;

  /// No description provided for @tournamentDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete tournament'**
  String get tournamentDeleteTitle;

  /// No description provided for @tournamentDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this tournament?'**
  String get tournamentDeleteMessage;

  /// No description provided for @tournamentEnded.
  ///
  /// In en, this message translates to:
  /// **'Tournament has ended'**
  String get tournamentEnded;

  /// No description provided for @tournamentLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading tournament'**
  String get tournamentLoadingTitle;

  /// No description provided for @tournamentBackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tournamentBackTooltip;

  /// No description provided for @tournamentOptionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Tournament options'**
  String get tournamentOptionsTooltip;

  /// No description provided for @tournamentShareStandings.
  ///
  /// In en, this message translates to:
  /// **'Share standings'**
  String get tournamentShareStandings;

  /// No description provided for @tournamentStatusMenu.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get tournamentStatusMenu;

  /// No description provided for @tournamentGroupMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Group matches'**
  String get tournamentGroupMatchesTitle;

  /// No description provided for @tournamentAddRound.
  ///
  /// In en, this message translates to:
  /// **'Add round'**
  String get tournamentAddRound;

  /// No description provided for @tournamentScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get tournamentScheduleTitle;

  /// No description provided for @tournamentCreateCustomMatchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create custom match'**
  String get tournamentCreateCustomMatchTooltip;

  /// No description provided for @tournamentSearchPlayerHint.
  ///
  /// In en, this message translates to:
  /// **'Search by player name (for example: A B)'**
  String get tournamentSearchPlayerHint;

  /// No description provided for @tournamentNoMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get tournamentNoMatchesFound;

  /// No description provided for @tournamentNoFixtures.
  ///
  /// In en, this message translates to:
  /// **'No fixtures yet'**
  String get tournamentNoFixtures;

  /// No description provided for @tournamentNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results yet'**
  String get tournamentNoResults;

  /// No description provided for @tournamentGenerateRoundWithExisting.
  ///
  /// In en, this message translates to:
  /// **'There are {count} matches in the schedule. Create another round?'**
  String tournamentGenerateRoundWithExisting(int count);

  /// No description provided for @tournamentGenerateRoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a round-robin round for all players?'**
  String get tournamentGenerateRoundMessage;

  /// No description provided for @tournamentNoPlayersTitle.
  ///
  /// In en, this message translates to:
  /// **'No players yet'**
  String get tournamentNoPlayersTitle;

  /// No description provided for @tournamentNoPlayersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add players to start the tournament'**
  String get tournamentNoPlayersSubtitle;

  /// No description provided for @tournamentShareStandingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Standings - {leagueName}'**
  String tournamentShareStandingsTitle(String leagueName);

  /// No description provided for @tournamentShareStandingsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Share standings'**
  String get tournamentShareStandingsSheetTitle;

  /// No description provided for @tournamentPreparingShare.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get tournamentPreparingShare;

  /// No description provided for @tournamentShareNow.
  ///
  /// In en, this message translates to:
  /// **'Share now'**
  String get tournamentShareNow;

  /// No description provided for @tournamentShareIncludeRankCost.
  ///
  /// In en, this message translates to:
  /// **'Include costs'**
  String get tournamentShareIncludeRankCost;

  /// No description provided for @tournamentLightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get tournamentLightTheme;

  /// No description provided for @tournamentDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get tournamentDarkTheme;

  /// No description provided for @tournamentHeroEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Tournament arena'**
  String get tournamentHeroEyebrow;

  /// No description provided for @tournamentHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage PES tournaments'**
  String get tournamentHeroTitle;

  /// No description provided for @tournamentMyStat.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get tournamentMyStat;

  /// No description provided for @tournamentLiveStat.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get tournamentLiveStat;

  /// No description provided for @tournamentPlayersStat.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get tournamentPlayersStat;

  /// No description provided for @tournamentJoinedTab.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get tournamentJoinedTab;

  /// No description provided for @tournamentManagedTab.
  ///
  /// In en, this message translates to:
  /// **'Managed'**
  String get tournamentManagedTab;

  /// No description provided for @tournamentOtherTab.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get tournamentOtherTab;

  /// No description provided for @tournamentJoinGroupFirst.
  ///
  /// In en, this message translates to:
  /// **'You have not joined any groups. Join a group first'**
  String get tournamentJoinGroupFirst;

  /// No description provided for @tournamentCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Tournament created successfully'**
  String get tournamentCreateSuccess;

  /// No description provided for @tournamentCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create tournament'**
  String get tournamentCreateButton;

  /// No description provided for @tournamentEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No tournaments'**
  String get tournamentEmptyTitle;

  /// No description provided for @tournamentEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new tournament to get started'**
  String get tournamentEmptySubtitle;

  /// No description provided for @tournamentManagedEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new tournament to start managing'**
  String get tournamentManagedEmptySubtitle;

  /// No description provided for @commonListEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get commonListEnd;

  /// No description provided for @dashboardLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load data'**
  String get dashboardLoadError;

  /// No description provided for @homeOngoingTournamentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ongoing tournaments'**
  String get homeOngoingTournamentsTitle;

  /// No description provided for @dashboardSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'You need to sign in'**
  String get dashboardSignInRequired;

  /// No description provided for @dashboardRecentForm10.
  ///
  /// In en, this message translates to:
  /// **'Last 10 match form'**
  String get dashboardRecentForm10;

  /// No description provided for @dashboardRecentMatches.
  ///
  /// In en, this message translates to:
  /// **'Recent matches'**
  String get dashboardRecentMatches;

  /// No description provided for @dashboardNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get dashboardNoMatches;

  /// No description provided for @dashboardHeroEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Control room'**
  String get dashboardHeroEyebrow;

  /// No description provided for @dashboardHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Track match performance'**
  String get dashboardHeroTitle;

  /// No description provided for @dashboardViewDetail.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get dashboardViewDetail;

  /// No description provided for @dashboardWinRate.
  ///
  /// In en, this message translates to:
  /// **'Win rate'**
  String get dashboardWinRate;

  /// No description provided for @dashboardGoalDifference.
  ///
  /// In en, this message translates to:
  /// **'Goal difference'**
  String get dashboardGoalDifference;

  /// No description provided for @dashboardMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get dashboardMatches;

  /// No description provided for @dashboardMatchesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} matches'**
  String dashboardMatchesCount(int count);

  /// No description provided for @dashboardNoValue.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get dashboardNoValue;

  /// No description provided for @dashboardNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get dashboardNoData;

  /// No description provided for @dashboardTournamentsJoined.
  ///
  /// In en, this message translates to:
  /// **'Tournaments joined'**
  String get dashboardTournamentsJoined;

  /// No description provided for @dashboardChampionRate.
  ///
  /// In en, this message translates to:
  /// **'Champion rate'**
  String get dashboardChampionRate;

  /// No description provided for @dashboardRunnerUpRate.
  ///
  /// In en, this message translates to:
  /// **'Runner-up rate'**
  String get dashboardRunnerUpRate;

  /// No description provided for @dashboardLatestChampion.
  ///
  /// In en, this message translates to:
  /// **'Latest championship'**
  String get dashboardLatestChampion;

  /// No description provided for @dashboardToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardToday;

  /// No description provided for @dashboardDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String dashboardDaysAgo(int count);

  /// No description provided for @dashboardInsufficientChartData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data to draw chart'**
  String get dashboardInsufficientChartData;

  /// No description provided for @dashboardPointsPerMatch.
  ///
  /// In en, this message translates to:
  /// **'Points / match'**
  String get dashboardPointsPerMatch;

  /// No description provided for @dashboardGoalDifferencePerMatch.
  ///
  /// In en, this message translates to:
  /// **'Goal diff / match'**
  String get dashboardGoalDifferencePerMatch;

  /// No description provided for @dashboardH2HTitle.
  ///
  /// In en, this message translates to:
  /// **'Head-to-head history'**
  String get dashboardH2HTitle;

  /// No description provided for @dashboardNoH2HData.
  ///
  /// In en, this message translates to:
  /// **'No head-to-head data yet'**
  String get dashboardNoH2HData;

  /// No description provided for @dashboardStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stats dashboard'**
  String get dashboardStatsTitle;

  /// No description provided for @dashboardDetailEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Dashboard detail'**
  String get dashboardDetailEyebrow;

  /// No description provided for @dashboardDetailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full match performance overview'**
  String get dashboardDetailSubtitle;

  /// No description provided for @dashboardRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Update from server'**
  String get dashboardRefreshTooltip;

  /// No description provided for @dashboardOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get dashboardOverview;

  /// No description provided for @dashboardMetricTournamentsJoined.
  ///
  /// In en, this message translates to:
  /// **'Tournaments joined'**
  String get dashboardMetricTournamentsJoined;

  /// No description provided for @dashboardMetricMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get dashboardMetricMatches;

  /// No description provided for @dashboardMetricLatestChampion.
  ///
  /// In en, this message translates to:
  /// **'Latest championship'**
  String get dashboardMetricLatestChampion;

  /// No description provided for @dashboardMetricWdlCount.
  ///
  /// In en, this message translates to:
  /// **'Wins / Draws / Losses'**
  String get dashboardMetricWdlCount;

  /// No description provided for @dashboardMetricWdlRate.
  ///
  /// In en, this message translates to:
  /// **'W / D / L rate'**
  String get dashboardMetricWdlRate;

  /// No description provided for @dashboardMetricGoals.
  ///
  /// In en, this message translates to:
  /// **'GF / GA / Goal diff'**
  String get dashboardMetricGoals;

  /// No description provided for @dashboardMetricChampion.
  ///
  /// In en, this message translates to:
  /// **'Champion'**
  String get dashboardMetricChampion;

  /// No description provided for @dashboardMetricRunnerUp.
  ///
  /// In en, this message translates to:
  /// **'Runner-up'**
  String get dashboardMetricRunnerUp;

  /// No description provided for @dashboardRecentLeagueForm5.
  ///
  /// In en, this message translates to:
  /// **'Last 5 tournament form'**
  String get dashboardRecentLeagueForm5;

  /// No description provided for @dashboardRefreshTitle.
  ///
  /// In en, this message translates to:
  /// **'Update stats?'**
  String get dashboardRefreshTitle;

  /// No description provided for @dashboardRefreshMessage.
  ///
  /// In en, this message translates to:
  /// **'The system will recalculate all stats from match data. This may take a few seconds.'**
  String get dashboardRefreshMessage;

  /// No description provided for @dashboardH2HSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Head-to-head'**
  String get dashboardH2HSectionTitle;

  /// No description provided for @dashboardH2HSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nemesis and favorable opponents from matchup history'**
  String get dashboardH2HSectionSubtitle;

  /// No description provided for @dashboardH2HSortMostMatches.
  ///
  /// In en, this message translates to:
  /// **'Most matches'**
  String get dashboardH2HSortMostMatches;

  /// No description provided for @dashboardH2HSortWins.
  ///
  /// In en, this message translates to:
  /// **'Most wins'**
  String get dashboardH2HSortWins;

  /// No description provided for @dashboardH2HSortLosses.
  ///
  /// In en, this message translates to:
  /// **'Most losses'**
  String get dashboardH2HSortLosses;

  /// No description provided for @dashboardNemesis.
  ///
  /// In en, this message translates to:
  /// **'Nemesis'**
  String get dashboardNemesis;

  /// No description provided for @dashboardFavorableOpponent.
  ///
  /// In en, this message translates to:
  /// **'Favorable'**
  String get dashboardFavorableOpponent;

  /// No description provided for @dashboardLossMetric.
  ///
  /// In en, this message translates to:
  /// **'losses'**
  String get dashboardLossMetric;

  /// No description provided for @dashboardWinMetric.
  ///
  /// In en, this message translates to:
  /// **'wins'**
  String get dashboardWinMetric;

  /// No description provided for @dashboardWdlWin.
  ///
  /// In en, this message translates to:
  /// **'Win'**
  String get dashboardWdlWin;

  /// No description provided for @dashboardWdlDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get dashboardWdlDraw;

  /// No description provided for @dashboardWdlLoss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get dashboardWdlLoss;

  /// No description provided for @dashboardWdlWinShort.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get dashboardWdlWinShort;

  /// No description provided for @dashboardWdlDrawShort.
  ///
  /// In en, this message translates to:
  /// **'D'**
  String get dashboardWdlDrawShort;

  /// No description provided for @dashboardWdlLossShort.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get dashboardWdlLossShort;

  /// No description provided for @dashboardOpponentRecordLine.
  ///
  /// In en, this message translates to:
  /// **'{count} / {total} matches {metric}'**
  String dashboardOpponentRecordLine(int count, int total, Object metric);

  /// No description provided for @dashboardWinRateValue.
  ///
  /// In en, this message translates to:
  /// **'{value}% win'**
  String dashboardWinRateValue(int value);

  /// No description provided for @dashboardNeedMoreH2H.
  ///
  /// In en, this message translates to:
  /// **'Need ≥ {count} matches\nagainst the same opponent'**
  String dashboardNeedMoreH2H(int count);

  /// No description provided for @dashboardMinMatchesChip.
  ///
  /// In en, this message translates to:
  /// **'>= {count} matches'**
  String dashboardMinMatchesChip(int count);

  /// No description provided for @dashboardThresholdTooltip.
  ///
  /// In en, this message translates to:
  /// **'Customize threshold'**
  String get dashboardThresholdTooltip;

  /// No description provided for @dashboardViewAllOpponents.
  ///
  /// In en, this message translates to:
  /// **'View all opponents'**
  String get dashboardViewAllOpponents;

  /// No description provided for @dashboardMinMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Minimum match threshold'**
  String get dashboardMinMatchesTitle;

  /// No description provided for @dashboardMinMatchesDescription.
  ///
  /// In en, this message translates to:
  /// **'An opponent must have at least {count} head-to-head matches to count toward \"Nemesis\" / \"Favorable opponent\". Increase this to reduce noise from small samples.'**
  String dashboardMinMatchesDescription(int count);

  /// No description provided for @dashboardMatchesUnit.
  ///
  /// In en, this message translates to:
  /// **'matches'**
  String get dashboardMatchesUnit;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackTitle;

  /// No description provided for @feedbackSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'You need to sign in to send feedback.'**
  String get feedbackSignInRequired;

  /// No description provided for @feedbackCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create feedback'**
  String get feedbackCreateTitle;

  /// No description provided for @feedbackTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get feedbackTitleHint;

  /// No description provided for @feedbackContentHint.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get feedbackContentHint;

  /// No description provided for @feedbackRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all information.'**
  String get feedbackRequired;

  /// No description provided for @feedbackMinimumLength.
  ///
  /// In en, this message translates to:
  /// **'Title must have at least 5 characters\nContent must have at least 10 characters.'**
  String get feedbackMinimumLength;

  /// No description provided for @feedbackSent.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent successfully!'**
  String get feedbackSent;

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdateSuccess;

  /// No description provided for @profileUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update profile'**
  String get profileUpdateTitle;

  /// No description provided for @profileSetupEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Profile setup'**
  String get profileSetupEyebrow;

  /// No description provided for @profileCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get profileCompleteTitle;

  /// No description provided for @profileCompleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a display name to keep using online features.'**
  String get profileCompleteSubtitle;

  /// No description provided for @profileContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get profileContinue;

  /// No description provided for @profileDisplayInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Display info'**
  String get profileDisplayInfoTitle;

  /// No description provided for @profileDisplayInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your name, phone number, and email.'**
  String get profileDisplayInfoSubtitle;

  /// No description provided for @profileFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profileFullNameHint;

  /// No description provided for @profilePhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get profilePhoneHint;

  /// No description provided for @notificationActivityEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Activity feed'**
  String get notificationActivityEyebrow;

  /// No description provided for @notificationAllRead.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get notificationAllRead;

  /// No description provided for @notificationUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} new notifications'**
  String notificationUnreadCount(int count);

  /// No description provided for @notificationMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationMarkAllRead;

  /// No description provided for @notificationRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get notificationRead;

  /// No description provided for @profileAppSection.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get profileAppSection;

  /// No description provided for @profileOfflineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline mode'**
  String get profileOfflineMode;

  /// No description provided for @profileSyncOfflineData.
  ///
  /// In en, this message translates to:
  /// **'Sync offline data'**
  String get profileSyncOfflineData;

  /// No description provided for @profileOtherOptions.
  ///
  /// In en, this message translates to:
  /// **'Other options'**
  String get profileOtherOptions;

  /// No description provided for @profileInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get profileInfoSection;

  /// No description provided for @profileRateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get profileRateApp;

  /// No description provided for @profileFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get profileFeedback;

  /// No description provided for @profileSessionSection.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get profileSessionSection;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @profileChangeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Change avatar'**
  String get profileChangeAvatar;

  /// No description provided for @profileDeleteAvatar.
  ///
  /// In en, this message translates to:
  /// **'Delete avatar'**
  String get profileDeleteAvatar;

  /// No description provided for @profileEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditTooltip;

  /// No description provided for @profileOfflineModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline mode'**
  String get profileOfflineModeTitle;

  /// No description provided for @profileOfflineModeMessage.
  ///
  /// In en, this message translates to:
  /// **'Offline mode lets you create data on this device only. Data is stored locally and will not be synced.\n\nAre you sure you want to switch to offline mode?'**
  String get profileOfflineModeMessage;

  /// No description provided for @profileAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get profileAccept;

  /// No description provided for @profileSignOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get profileSignOutMessage;

  /// No description provided for @ownershipProcessFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not process ownership: {error}'**
  String ownershipProcessFailed(String error);

  /// No description provided for @ownershipResolutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Resolve ownership'**
  String get ownershipResolutionTitle;

  /// No description provided for @ownershipResolutionMessage.
  ///
  /// In en, this message translates to:
  /// **'You own the groups/tournaments below. Transfer ownership to another member or deactivate them before deleting your account.'**
  String get ownershipResolutionMessage;

  /// No description provided for @ownershipGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get ownershipGroup;

  /// No description provided for @ownershipTournament.
  ///
  /// In en, this message translates to:
  /// **'Tournament'**
  String get ownershipTournament;

  /// No description provided for @ownershipContinueDelete.
  ///
  /// In en, this message translates to:
  /// **'Continue deleting account'**
  String get ownershipContinueDelete;

  /// No description provided for @ownershipTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get ownershipTransfer;

  /// No description provided for @ownershipDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get ownershipDeactivate;
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
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
