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
}
