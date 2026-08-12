// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'PES Arena';

  @override
  String get mainTabArena => 'Arena';

  @override
  String get mainTabGroups => 'Groups';

  @override
  String get mainTabTournaments => 'Tournaments';

  @override
  String get mainTabProfile => 'Profile';

  @override
  String get languageTitle => 'Choose your language';

  @override
  String get languageSubtitle => 'You can change this later in settings.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageSystemMatch => 'Suggested from your device';

  @override
  String get continueButton => 'Continue';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsHeroEyebrow => 'Preferences';

  @override
  String get settingsHeroSubtitle => 'Security, appearance, and account.';

  @override
  String get settingsUpdateProfile => 'Update profile';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsDarkMode => 'Dark mode';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteConfirmTitle => 'Confirm';

  @override
  String get settingsDeleteConfirmMessage =>
      'Are you sure you want to delete your account?\n\nAll of your personal data will be deleted and cannot be restored. Some data related to groups and other players will be kept.';

  @override
  String get cancel => 'Cancel';

  @override
  String ownershipCheckFailed(String error) {
    return 'Could not check ownership: $error';
  }

  @override
  String get authContinue => 'Sign in to continue';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authRegister => 'Register';

  @override
  String get authForgotPassword => 'Forgot password';

  @override
  String get authResetPasswordSubmit => 'Send reset email';

  @override
  String get authResetPasswordSent => 'Password reset email sent';

  @override
  String get authSignInSuccess => 'Signed in successfully';

  @override
  String get authEmailHint => 'Email';

  @override
  String get authPasswordHint => 'Password';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String get authVerifyAccountTitle => 'Verify account';

  @override
  String get authVerificationSent =>
      'A verification code has been sent to your phone number';

  @override
  String get authVerificationCode => 'Verification code';

  @override
  String get authVerify => 'Verify';

  @override
  String get profileChangePasswordTitle => 'Change password';

  @override
  String get profileCurrentPasswordHint => 'Current password';

  @override
  String get profileNewPasswordHint => 'New password';

  @override
  String get profileConfirmNewPasswordHint => 'Confirm new password';

  @override
  String get profileChangePasswordSuccess => 'Password changed successfully';

  @override
  String get profileSecurityEyebrow => 'Security';

  @override
  String get profileSecuritySubtitle =>
      'Update your password to protect your account.';

  @override
  String get or => 'Or';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get backHome => 'Back home';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSend => 'Send';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonUpdate => 'Update';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonBack => 'Back';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get commonErrorTitle => 'Something went wrong';

  @override
  String get commonRetryLater => 'Please try again later';

  @override
  String get commonDone => 'Done';

  @override
  String get commonSearchByName => 'Search by name';

  @override
  String get tablePlayer => 'Player';

  @override
  String get tableMatchesPlayedShort => 'MP';

  @override
  String get tableWinsShort => 'W';

  @override
  String get tableDrawsShort => 'D';

  @override
  String get tableLossesShort => 'L';

  @override
  String get tableGoalsForShort => 'GF';

  @override
  String get tableGoalsAgainstShort => 'GA';

  @override
  String get tableGoalDifferenceShort => 'GD';

  @override
  String get tablePointsShort => 'Pts';

  @override
  String get groupCreateSuccess => 'Group created successfully';

  @override
  String get groupCreateTitle => 'Create new group';

  @override
  String get groupNameHint => 'Group name';

  @override
  String get groupDescriptionHint => 'Group description';

  @override
  String get groupNameRequired => 'Group name cannot be empty';

  @override
  String get groupCreateButton => 'Create group';

  @override
  String get groupEmptyTitle => 'No groups';

  @override
  String get groupEmptySubtitle => 'Create a new group to get started';

  @override
  String get groupHeroEyebrow => 'Community hub';

  @override
  String get groupHeroTitle => 'Manage PES groups';

  @override
  String get groupCreateNew => 'Create';

  @override
  String get groupMineStat => 'Mine';

  @override
  String get groupDiscoverStat => 'Discover';

  @override
  String get groupMembersStat => 'Members';

  @override
  String groupMemberCount(int count) {
    return '$count members';
  }

  @override
  String get groupMyGroupsTab => 'My groups';

  @override
  String get groupOtherGroupsTab => 'Other groups';

  @override
  String get groupAddMemberTitle => 'Add member';

  @override
  String get groupCreatePlaceholderPlayer => 'Create new player (placeholder)';

  @override
  String get groupCreateNewPlayer => 'Create new player';

  @override
  String get groupDeleteWarning =>
      'This will permanently delete the group, all tournaments, matches, standings, and related stats. Data cannot be restored.';

  @override
  String get groupSearchByNameHint => 'Search by name';

  @override
  String get groupPlayerNameHint => 'Player name';

  @override
  String get groupAddMemberSuccess => 'Member added successfully';

  @override
  String get groupPlayerAddedSuccess => 'New player added';

  @override
  String get groupUpdateStatusFailed => 'Could not update status';

  @override
  String get groupDeleteRequestSent => 'Group deletion request sent';

  @override
  String get groupDeleteTitle => 'Delete group';

  @override
  String get groupOverviewTab => 'Overview';

  @override
  String get groupMembersTab => 'Members';

  @override
  String get groupInactive => 'Inactive';

  @override
  String get groupDescriptionTitle => 'Description';

  @override
  String get groupNoOverview => 'No overview data yet';

  @override
  String get groupRefreshStatsTitle => 'Update stats?';

  @override
  String get groupRefreshStatsTooltip => 'Update stats';

  @override
  String get groupOverviewTitle => 'Group overview';

  @override
  String get groupYearFilterAll => 'All';

  @override
  String get groupRefreshStatsMessage =>
      'The system will reload all tournaments and recalculate group stats. This may take a few seconds.';

  @override
  String get groupOverviewLoadFailed => 'Could not load overview data.';

  @override
  String groupOverviewLoadError(String message) {
    return 'Overview load error: $message';
  }

  @override
  String get groupLegendChampion => 'Unbeatable';

  @override
  String get groupLegendRunnerUp => 'Great runner-up';

  @override
  String get groupLegendPro => 'Pro';

  @override
  String get groupLegendDefense => 'Steel defense';

  @override
  String get groupTitles => 'Titles';

  @override
  String get groupMemberStats => 'Member stats';

  @override
  String get groupNotEnoughAwardsData =>
      'Not enough data to award titles (requires at least 5 finished tournaments or 5 matches).';

  @override
  String get groupNoMemberStats => 'No member data yet.';

  @override
  String get groupReplaceSuccess => 'Replaced successfully';

  @override
  String get groupReplaceError => 'Something went wrong, please try again';

  @override
  String get groupReplaceSelectOld => 'Choose player to replace';

  @override
  String get groupReplaceSelectNew => 'Choose replacement';

  @override
  String get groupReplaceConfirm => 'Confirm replacement';

  @override
  String get groupNoSearchResults => 'No results';

  @override
  String get groupReplaceOldLabel => 'Replace';

  @override
  String get groupReplaceNewLabel => 'With';

  @override
  String get groupReplaceMergeWarning =>
      'This player is already in the tournament. Stats for both players will be merged.';

  @override
  String get groupActionIrreversible => 'This action cannot be undone.';

  @override
  String get groupClose => 'Close';

  @override
  String get groupPlaceholder => 'Placeholder';

  @override
  String get costRankPayoutRequired =>
      'Enter rank payout amounts (for example: 50, 100)';

  @override
  String get costBracketPayoutTitle => 'Calculate by bracket';

  @override
  String get costRankPayoutTitle => 'Calculate by rank';

  @override
  String get costBracketPayoutSubtitle =>
      'Champion receives money from runner-up and earlier eliminated players';

  @override
  String get costRankPayoutSubtitle =>
      'Lower ranks contribute to first place using this configuration';

  @override
  String get costPayoutHint => 'Example: 50, 100, 150 (k VND)';

  @override
  String get costBracketPayoutOrder =>
      'In order: runner-up, each semifinal loser, each quarterfinal loser...';

  @override
  String get costRankPayoutOrder =>
      'In order: rank 2, rank 3, rank 4... pay rank 1.';

  @override
  String get costDefaultMatchCostHint => 'Default amount per match (k VND)';

  @override
  String get costDefaultMatchCostHelp =>
      'This amount is prefilled when cost is enabled for a match while entering the result.';

  @override
  String get costDefaultPerGoalTitle =>
      'Enable goal-difference cost by default';

  @override
  String get costDefaultPerGoalSubtitle =>
      'Loser pays extra by goal difference (for example: 3-1 adds this amount twice).';

  @override
  String get costPerGoalHint => 'Amount per goal (k VND)';

  @override
  String get costPerGoalHelp =>
      'Added to the per-match amount when that match also has cost enabled.';

  @override
  String get costSuggestions => 'Suggestions:';

  @override
  String costPresetAmountLabel(String amounts) {
    return '$amounts k';
  }

  @override
  String get tournamentSelectGroupRequired => 'Select a group';

  @override
  String get tournamentParticipantsMinimum => 'Select at least 2 participants';

  @override
  String get tournamentCupPowerOfTwoRequired =>
      'Cup requires participant count to be a power of 2 (2, 4, 8, 16...)';

  @override
  String get tournamentFullKnockoutPowerOfTwoRequired =>
      'Groups x knockout qualifiers must be a power of 2';

  @override
  String get tournamentNameRequired => 'Enter a tournament name';

  @override
  String get tournamentStartBeforeEndRequired =>
      'Start date must be before end date';

  @override
  String get tournamentEndAfterStartRequired =>
      'End date must be after start date';

  @override
  String get tournamentNoGroupsTitle => 'You have not joined any groups';

  @override
  String get tournamentNoGroupsSubtitle =>
      'Create or join a group before creating a tournament';

  @override
  String get tournamentSelectGroupTitle => 'Select group';

  @override
  String get tournamentSelectGroupSubtitle =>
      'This tournament will belong to this group';

  @override
  String tournamentMembersCount(int count) {
    return '$count members';
  }

  @override
  String get tournamentAddPlayersTitle => 'Add players';

  @override
  String tournamentAddPlayersSubtitle(int count) {
    return 'Select at least 2 players ($count selected)';
  }

  @override
  String get tournamentModeTitle => 'Tournament mode';

  @override
  String get tournamentModeSubtitle => 'Choose competition format';

  @override
  String get tournamentModeLeague => 'League';

  @override
  String get tournamentModeLeagueSubtitle =>
      'Round robin, everyone plays each other';

  @override
  String get tournamentModeCup => 'Cup';

  @override
  String get tournamentModeCupSubtitle => 'Knockout, one loss and out';

  @override
  String get tournamentModeFull => 'Full';

  @override
  String get tournamentModeFullSubtitle => 'Group stage to knockout';

  @override
  String get tournamentConfigPreviewTitle => 'Configuration & Preview';

  @override
  String get tournamentConfigPreviewSubtitle => 'Customize before creating';

  @override
  String get tournamentInfoTitle => 'Tournament info';

  @override
  String get tournamentInfoSubtitle => 'Set name and dates';

  @override
  String get tournamentNameDescriptionTitle => 'Name & description';

  @override
  String get tournamentNameHint => 'Tournament name';

  @override
  String get tournamentDescriptionHint => 'Description (optional)';

  @override
  String get tournamentTimeTitle => 'Dates';

  @override
  String get tournamentStartDateHint => 'Start date';

  @override
  String get tournamentEndDateHint => 'End date';

  @override
  String get tournamentCostSubtitle => 'Can be configured later';

  @override
  String get tournamentStatsSynced => 'Scores synced';

  @override
  String get tournamentCostUpdated => 'Tournament cost updated';

  @override
  String get tournamentCustomMatchCreated => 'Match created successfully';

  @override
  String get tournamentCreateMatchTitle => 'Create match';

  @override
  String get tournamentMatchDeleted => 'Match deleted successfully';

  @override
  String get tournamentDeleted => 'Tournament deleted';

  @override
  String get tournamentStatusUpdated =>
      'Tournament status updated successfully';

  @override
  String get tournamentPlayerAdded => 'Player added successfully';

  @override
  String tournamentPlayersAdded(int count) {
    return '$count players added successfully';
  }

  @override
  String get tournamentGroupRoundMinimum =>
      'Group needs at least 2 players to create a leg';

  @override
  String get tournamentRoundCreated => 'Leg created successfully';

  @override
  String get tournamentMatchUpdated => 'Match updated successfully';

  @override
  String get tournamentMatchConcurrentUpdate =>
      'This match was just updated by someone else. Please check again.';

  @override
  String get tournamentBracketCreated => 'Bracket created successfully';

  @override
  String get tournamentFullCreated => 'Full tournament created successfully';

  @override
  String tournamentSelectedPlayersCount(int count) {
    return '$count selected:';
  }

  @override
  String tournamentAddPlayersCount(int count) {
    return 'Add $count players';
  }

  @override
  String get tournamentLoadingCost => 'Loading costs';

  @override
  String get tournamentNoCostTitle => 'No costs yet';

  @override
  String get tournamentNoCostSubtitle =>
      'Enable cost configuration or enter money in each match';

  @override
  String get tournamentHomeTeamHint => 'Home team';

  @override
  String get tournamentAwayTeamHint => 'Away team';

  @override
  String get tournamentSelectTeamRequired => 'Please select teams';

  @override
  String get tournamentDistinctTeamsRequired =>
      'Please select 2 different teams';

  @override
  String get tournamentUpdateResultTitle => 'Update result';

  @override
  String get tournamentMatchHasCost => 'This match has cost';

  @override
  String get tournamentMatchCostLabel => 'Amount (k VND)';

  @override
  String get tournamentAddGoalDifferenceCost => 'Add goal-difference cost';

  @override
  String get tournamentGoalDifferenceCostHelp =>
      'For example: 3-1 adds this amount twice.';

  @override
  String get tournamentScoreRequired => 'Enter match result';

  @override
  String get tournamentTabBracket => 'Bracket';

  @override
  String get tournamentTabResults => 'Results';

  @override
  String get tournamentTabCost => 'Costs';

  @override
  String get tournamentTabGroups => 'Groups';

  @override
  String tournamentGroupLabel(String groupId) {
    return 'Group $groupId';
  }

  @override
  String get tournamentTabStandings => 'Standings';

  @override
  String get tournamentTabFixtures => 'Schedule';

  @override
  String get tournamentStatusTitle => 'Tournament status';

  @override
  String get tournamentRecomputeStatsTitle => 'Sync scores';

  @override
  String get tournamentRecomputeStatsMessage =>
      'Recalculate all scores from finished match results? Use this when scores are inconsistent due to old data.';

  @override
  String get tournamentRecomputeStatsConfirm => 'Sync';

  @override
  String get tournamentDeleteTitle => 'Delete tournament';

  @override
  String get tournamentDeleteMessage =>
      'Are you sure you want to delete this tournament?';

  @override
  String get tournamentEnded => 'Tournament has ended';

  @override
  String get tournamentLoadingTitle => 'Loading tournament';

  @override
  String get tournamentBackTooltip => 'Back';

  @override
  String get tournamentOptionsTooltip => 'Tournament options';

  @override
  String get tournamentShareStandings => 'Share standings';

  @override
  String get tournamentStatusMenu => 'Status';

  @override
  String get tournamentGroupMatchesTitle => 'Group matches';

  @override
  String get tournamentAddRound => 'Add leg';

  @override
  String get tournamentScheduleTitle => 'Schedule';

  @override
  String get tournamentCreateCustomMatchTooltip => 'Create custom match';

  @override
  String get tournamentSearchPlayerHint =>
      'Search by player name (for example: A B)';

  @override
  String get tournamentNoMatchesFound => 'No matches found';

  @override
  String get tournamentNoFixtures => 'No fixtures yet';

  @override
  String get tournamentNoResults => 'No results yet';

  @override
  String tournamentGenerateRoundWithExisting(int count) {
    return 'There are $count fixtures already. Create another leg, split into matchdays?';
  }

  @override
  String tournamentMatchdayLabel(int n) {
    return 'Round $n';
  }

  @override
  String tournamentMatchdayBadge(int n) {
    return 'MD $n';
  }

  @override
  String get tournamentOtherMatches => 'Other matches';

  @override
  String tournamentRoundTooLarge(int max) {
    return 'This league has too many players to generate a leg in one go (max $max).';
  }

  @override
  String get tournamentGenerateRoundMessage =>
      'Create a new leg? Fixtures will be split into matchdays.';

  @override
  String get tournamentNoPlayersTitle => 'No players yet';

  @override
  String get tournamentNoPlayersSubtitle =>
      'Add players to start the tournament';

  @override
  String tournamentShareStandingsTitle(String leagueName) {
    return 'Standings - $leagueName';
  }

  @override
  String get tournamentShareStandingsSheetTitle => 'Share standings';

  @override
  String get tournamentPreparingShare => 'Preparing...';

  @override
  String get tournamentShareNow => 'Share now';

  @override
  String get tournamentShareIncludeRankCost => 'Include costs';

  @override
  String get tournamentLightTheme => 'Light';

  @override
  String get tournamentDarkTheme => 'Dark';

  @override
  String get tournamentHeroEyebrow => 'Tournament arena';

  @override
  String get tournamentHeroTitle => 'Manage PES tournaments';

  @override
  String get tournamentMyStat => 'Mine';

  @override
  String get tournamentLiveStat => 'Live';

  @override
  String get tournamentPlayersStat => 'Players';

  @override
  String get tournamentJoinedTab => 'Joined';

  @override
  String get tournamentManagedTab => 'Managed';

  @override
  String get tournamentOtherTab => 'Other';

  @override
  String get tournamentJoinGroupFirst =>
      'You have not joined any groups. Join a group first';

  @override
  String get tournamentCreatingLeague => 'Creating league…';

  @override
  String get tournamentSavingMatch => 'Saving result';

  @override
  String get tournamentCreateSuccess => 'Tournament created successfully';

  @override
  String get tournamentCreateButton => 'Create tournament';

  @override
  String get tournamentEmptyTitle => 'No tournaments';

  @override
  String get tournamentEmptySubtitle =>
      'Create a new tournament to get started';

  @override
  String get tournamentManagedEmptySubtitle =>
      'Create a new tournament to start managing';

  @override
  String get commonListEnd => 'End';

  @override
  String get dashboardLoadError => 'Could not load data';

  @override
  String get homeOngoingTournamentsTitle => 'Ongoing tournaments';

  @override
  String get dashboardSignInRequired => 'You need to sign in';

  @override
  String get dashboardRecentForm10 => 'Last 10 match form';

  @override
  String get dashboardRecentMatches => 'Recent matches';

  @override
  String get dashboardNoMatches => 'No matches yet';

  @override
  String get dashboardHeroEyebrow => 'Control room';

  @override
  String get dashboardHeroTitle => 'Track match performance';

  @override
  String get dashboardViewDetail => 'View details';

  @override
  String get dashboardWinRate => 'Win rate';

  @override
  String get dashboardGoalDifference => 'Goal difference';

  @override
  String get dashboardMatches => 'Matches';

  @override
  String dashboardMatchesCount(int count) {
    return '$count matches';
  }

  @override
  String get dashboardNoValue => '—';

  @override
  String get dashboardNoData => 'No data';

  @override
  String get dashboardTournamentsJoined => 'Tournaments joined';

  @override
  String get dashboardChampionRate => 'Champion rate';

  @override
  String get dashboardRunnerUpRate => 'Runner-up rate';

  @override
  String get dashboardLatestChampion => 'Latest championship';

  @override
  String get dashboardToday => 'Today';

  @override
  String dashboardDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get dashboardInsufficientChartData => 'Not enough data to draw chart';

  @override
  String get dashboardPointsPerMatch => 'Points / match';

  @override
  String get dashboardGoalDifferencePerMatch => 'Goal diff / match';

  @override
  String get dashboardH2HTitle => 'Head-to-head history';

  @override
  String get dashboardNoH2HData => 'No head-to-head data yet';

  @override
  String get dashboardStatsTitle => 'Stats dashboard';

  @override
  String get dashboardDetailEyebrow => 'Dashboard detail';

  @override
  String get dashboardDetailSubtitle => 'Full match performance overview';

  @override
  String get dashboardRefreshTooltip => 'Update from server';

  @override
  String get dashboardOverview => 'Overview';

  @override
  String get dashboardMetricTournamentsJoined => 'Tournaments joined';

  @override
  String get dashboardMetricMatches => 'Matches';

  @override
  String get dashboardMetricLatestChampion => 'Latest championship';

  @override
  String get dashboardMetricWdlCount => 'Wins / Draws / Losses';

  @override
  String get dashboardMetricWdlRate => 'W / D / L rate';

  @override
  String get dashboardMetricGoals => 'GF / GA / Goal diff';

  @override
  String get dashboardMetricChampion => 'Champion';

  @override
  String get dashboardMetricRunnerUp => 'Runner-up';

  @override
  String get dashboardRecentLeagueForm5 => 'Last 5 tournament form';

  @override
  String get dashboardRefreshTitle => 'Update stats?';

  @override
  String get dashboardRefreshMessage =>
      'The system will recalculate all stats from match data. This may take a few seconds.';

  @override
  String get dashboardH2HSectionTitle => 'Head-to-head';

  @override
  String get dashboardH2HSectionSubtitle =>
      'Nemesis and favorable opponents from matchup history';

  @override
  String get dashboardH2HSortMostMatches => 'Most matches';

  @override
  String get dashboardH2HSortWins => 'Most wins';

  @override
  String get dashboardH2HSortLosses => 'Most losses';

  @override
  String get dashboardNemesis => 'Nemesis';

  @override
  String get dashboardFavorableOpponent => 'Favorable';

  @override
  String get dashboardLossMetric => 'losses';

  @override
  String get dashboardWinMetric => 'wins';

  @override
  String get dashboardWdlWin => 'Win';

  @override
  String get dashboardWdlDraw => 'Draw';

  @override
  String get dashboardWdlLoss => 'Loss';

  @override
  String get dashboardWdlWinShort => 'W';

  @override
  String get dashboardWdlDrawShort => 'D';

  @override
  String get dashboardWdlLossShort => 'L';

  @override
  String dashboardOpponentRecordLine(int count, int total, Object metric) {
    return '$count / $total matches $metric';
  }

  @override
  String dashboardWinRateValue(int value) {
    return '$value% win';
  }

  @override
  String dashboardNeedMoreH2H(int count) {
    return 'Need ≥ $count matches\nagainst the same opponent';
  }

  @override
  String dashboardMinMatchesChip(int count) {
    return '>= $count matches';
  }

  @override
  String get dashboardThresholdTooltip => 'Customize threshold';

  @override
  String get dashboardViewAllOpponents => 'View all opponents';

  @override
  String get dashboardMinMatchesTitle => 'Minimum match threshold';

  @override
  String dashboardMinMatchesDescription(int count) {
    return 'An opponent must have at least $count head-to-head matches to count toward \"Nemesis\" / \"Favorable opponent\". Increase this to reduce noise from small samples.';
  }

  @override
  String get dashboardMatchesUnit => 'matches';

  @override
  String get profileUpdateSuccess => 'Profile updated successfully';

  @override
  String get profileUpdateTitle => 'Update profile';

  @override
  String get profileSetupEyebrow => 'Profile setup';

  @override
  String get profileCompleteTitle => 'Complete your profile';

  @override
  String get profileCompleteSubtitle =>
      'Enter a display name to keep using online features.';

  @override
  String get profileContinue => 'Continue';

  @override
  String get profileDisplayInfoTitle => 'Display info';

  @override
  String get profileDisplayInfoSubtitle =>
      'Update your name, phone number, and email.';

  @override
  String get profileFullNameHint => 'Full name';

  @override
  String get profilePhoneHint => 'Phone number';

  @override
  String get profileAppSection => 'App';

  @override
  String get profileOtherOptions => 'Other options';

  @override
  String get profileInfoSection => 'Info';

  @override
  String get profileVersion => 'Version';

  @override
  String get profileSessionSection => 'Session';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileChangeAvatar => 'Change avatar';

  @override
  String get profileDeleteAvatar => 'Delete avatar';

  @override
  String get profileEditTooltip => 'Edit profile';

  @override
  String get profileSignOutMessage => 'Are you sure you want to sign out?';

  @override
  String ownershipProcessFailed(String error) {
    return 'Could not process ownership: $error';
  }

  @override
  String get ownershipResolutionTitle => 'Resolve ownership';

  @override
  String get ownershipResolutionMessage =>
      'You own the groups/tournaments below. Transfer ownership to another member or deactivate them before deleting your account.';

  @override
  String get ownershipGroup => 'Group';

  @override
  String get ownershipTournament => 'Tournament';

  @override
  String get ownershipContinueDelete => 'Continue deleting account';

  @override
  String get ownershipTransfer => 'Transfer';

  @override
  String get ownershipDeactivate => 'Deactivate';
}
