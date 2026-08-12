import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('AppLocalizations.of returns active localization', (
    tester,
  ) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(AppLocalizations.of(capturedContext).localeName, 'vi');
  });

  test('lookupAppLocalizations throws for unsupported locale', () {
    expect(
      () => lookupAppLocalizations(const Locale('fr')),
      throwsA(isA<FlutterError>()),
    );
  });

  test('ARB files exclude retired feature localization keys', () {
    final english = File('lib/l10n/app_en.arb').readAsStringSync();
    final vietnamese = File('lib/l10n/app_vi.arb').readAsStringSync();
    const retiredKeys = [
      'mainTabNotifications',
      'appOnline',
      'profileOfflineMode',
      'profileOfflineModeTitle',
      'profileOfflineModeMessage',
      'profileSyncOfflineData',
      'profileRateApp',
      'profileFeedback',
      'syncNoOfflineLeague',
      'syncNoGroup',
      'syncNoLeagueSelected',
      'syncChoose',
      'syncNoGroupMembers',
      'syncCreatePlaceholderUser',
      'syncNewPlayerName',
      'syncDisplayNameHint',
      'syncMissingData',
      'syncDateLabel',
      'syncTargetGroupLabel',
      'syncNoPlayedMatches',
      'syncSuccess',
      'syncRetry',
      'syncBack',
      'syncExit',
      'syncContinue',
      'syncOfflineLeagueSection',
      'syncOnlineGroupSection',
      'syncLeagueDescription',
      'syncPreview',
      'syncDuplicateMapping',
      'syncNotMapped',
      'syncNewTargetSuffix',
      'syncMapPlayerTitle',
      'syncWritingData',
      'syncDoNotClose',
      'syncSelectSourceTitle',
      'syncMapPlayersTitle',
      'syncConfirmTitle',
      'syncExecutingTitle',
      'syncOriginalOfflineTab',
      'syncOnlineWillCreateTab',
      'syncRun',
      'syncNewSuffix',
      'syncWritesCount',
      'syncStandingsTitle',
      'syncMatchResultsTitle',
      'syncNewPlayersWillBeCreated',
    ];

    for (final arb in [english, vietnamese]) {
      for (final key in retiredKeys) {
        expect(arb.contains('"$key"'), isFalse, reason: key);
      }
      expect(
        arb.contains(RegExp(r'^  "notification', multiLine: true)),
        isFalse,
      );
      expect(arb.contains(RegExp(r'^  "feedback', multiLine: true)), isFalse);
      expect(arb.contains(RegExp(r'^  "offline', multiLine: true)), isFalse);
    }
  });
}
