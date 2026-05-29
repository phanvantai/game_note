import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/widgets/share_preview_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';

const _openButtonKey = Key('open-share-preview-sheet');
const _validPngBytes = <int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  10,
  73,
  68,
  65,
  84,
  120,
  156,
  99,
  100,
  0,
  0,
  0,
  2,
  0,
  1,
  229,
  66,
  140,
  143,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
];

Widget _host({
  required ThemeData theme,
  required Uint8List darkImageBytes,
  required Uint8List lightImageBytes,
  Uint8List? darkCostImageBytes,
  Uint8List? lightCostImageBytes,
}) {
  return MaterialApp(
    locale: const Locale('vi'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: theme,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            key: _openButtonKey,
            onPressed: () => showSharePreviewBottomSheet(
              context: context,
              darkImageBytes: darkImageBytes,
              lightImageBytes: lightImageBytes,
              leagueName: 'Premier League',
              darkCostImageBytes: darkCostImageBytes,
              lightCostImageBytes: lightCostImageBytes,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openSheet(
  WidgetTester tester, {
  required Uint8List darkImageBytes,
  required Uint8List lightImageBytes,
  Uint8List? darkCostImageBytes,
  Uint8List? lightCostImageBytes,
  ThemeData? theme,
}) async {
  final activeTheme = theme ?? ThemeData();
  await tester.pumpWidget(
    _host(
      theme: activeTheme,
      darkImageBytes: darkImageBytes,
      lightImageBytes: lightImageBytes,
      darkCostImageBytes: darkCostImageBytes,
      lightCostImageBytes: lightCostImageBytes,
    ),
  );
  await tester.tap(find.byKey(_openButtonKey));
  await tester.pumpAndSettle();
}

void main() {
  final darkImageBytes = Uint8List.fromList(_validPngBytes);
  final lightImageBytes = Uint8List.fromList(_validPngBytes);
  final darkCostImageBytes = Uint8List.fromList(_validPngBytes);
  final lightCostImageBytes = Uint8List.fromList(_validPngBytes);

  tearDown(() {
    sharePreviewShare = SharePlus.instance.share;
    sharePreviewWriteFile = (imageBytes) async {
      final file = File('${Directory.systemTemp.path}/league_standings.png');
      await file.writeAsBytes(imageBytes);
      return file;
    };
  });

  test('default share writer writes image bytes to a temp file', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);

    final file = await sharePreviewWriteFile(bytes);
    addTearDown(() {
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    expect(await file.readAsBytes(), bytes);
  });

  testWidgets('render title, close/share buttons, and theme toggle labels', (
    tester,
  ) async {
    await _openSheet(
      tester,
      darkImageBytes: darkImageBytes,
      lightImageBytes: lightImageBytes,
    );

    expect(find.text('Chia sẻ bảng xếp hạng'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Đóng'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Chia sẻ ngay'), findsOneWidget);
    expect(find.text('Sáng'), findsOneWidget);
    expect(find.text('Tối'), findsOneWidget);
    expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('show and hide cost toggle based on cost image bytes', (
    tester,
  ) async {
    await _openSheet(
      tester,
      darkImageBytes: darkImageBytes,
      lightImageBytes: lightImageBytes,
      darkCostImageBytes: darkCostImageBytes,
      lightCostImageBytes: lightCostImageBytes,
    );
    expect(find.text('Kèm chi phí'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Đóng'));
    await tester.pumpAndSettle();

    await _openSheet(
      tester,
      darkImageBytes: darkImageBytes,
      lightImageBytes: lightImageBytes,
    );
    expect(find.text('Kèm chi phí'), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('toggle theme and cost switches update preview state', (
    tester,
  ) async {
    final theme = ThemeData.light();
    await _openSheet(
      tester,
      darkImageBytes: darkImageBytes,
      lightImageBytes: lightImageBytes,
      darkCostImageBytes: darkCostImageBytes,
      lightCostImageBytes: lightCostImageBytes,
      theme: theme,
    );

    expect(find.byKey(const ValueKey('false-false')), findsOneWidget);
    expect(find.byKey(const ValueKey('false-true')), findsNothing);
    expect(find.byType(Switch), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    final initialLightText = tester.widget<Text>(find.text('Sáng'));
    final initialDarkText = tester.widget<Text>(find.text('Tối'));
    expect(initialLightText.style?.color, theme.colorScheme.onSecondary);
    expect(initialDarkText.style?.color, theme.colorScheme.onSurfaceVariant);

    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('true-false')), findsOneWidget);
    final darkTextAfter = tester.widget<Text>(find.text('Tối'));
    final lightTextAfter = tester.widget<Text>(find.text('Sáng'));
    expect(lightTextAfter.style?.color, theme.colorScheme.onSurfaceVariant);
    expect(darkTextAfter.style?.color, theme.colorScheme.onSecondary);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.byKey(const ValueKey('true-true')), findsOneWidget);

    await tester.tap(find.text('Sáng'));
    await tester.pumpAndSettle();

    final lightTextAfterReset = tester.widget<Text>(find.text('Sáng'));
    final darkTextAfterReset = tester.widget<Text>(find.text('Tối'));
    expect(lightTextAfterReset.style?.color, theme.colorScheme.onSecondary);
    expect(darkTextAfterReset.style?.color, theme.colorScheme.onSurfaceVariant);
    expect(find.byKey(const ValueKey('false-true')), findsOneWidget);
  });

  testWidgets('tap cost row toggles include-cost via InkWell', (tester) async {
    await _openSheet(
      tester,
      darkImageBytes: darkImageBytes,
      lightImageBytes: lightImageBytes,
      darkCostImageBytes: darkCostImageBytes,
      lightCostImageBytes: lightCostImageBytes,
    );

    expect(find.byKey(const ValueKey('false-false')), findsOneWidget);

    await tester.tap(find.text('Kèm chi phí'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('false-true')), findsOneWidget);

    await tester.tap(find.text('Kèm chi phí'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('false-false')), findsOneWidget);
  });

  testWidgets('share button shows loading UI while share request is pending', (
    tester,
  ) async {
    final shareCompleter = Completer<ShareResult>();
    final shareParams = <ShareParams>[];
    sharePreviewShare = (params) {
      shareParams.add(params);
      return shareCompleter.future;
    };
    sharePreviewWriteFile = (_) async =>
        File('${Directory.systemTemp.path}/league_standings_test.png');

    await _openSheet(
      tester,
      darkImageBytes: darkImageBytes,
      lightImageBytes: lightImageBytes,
      darkCostImageBytes: darkCostImageBytes,
      lightCostImageBytes: lightCostImageBytes,
    );

    final initialShareButton = find.widgetWithText(
      FilledButton,
      'Chia sẻ ngay',
    );
    await tester.tap(initialShareButton);
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('Đang chuẩn bị...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final shareButton = find.widgetWithText(FilledButton, 'Đang chuẩn bị...');
    expect(tester.widget<FilledButton>(shareButton).onPressed, isNull);
    await tester.pump();
    expect(shareParams, hasLength(1));
    expect(shareParams.single.title, 'Bảng xếp hạng - Premier League');
    expect(shareParams.single.files, hasLength(1));

    shareCompleter.complete(
      ShareResult(
        'dev.fluttercommunity.plus/share/success',
        ShareResultStatus.success,
      ),
    );
    await tester.pump();
    expect(find.widgetWithText(FilledButton, 'Chia sẻ ngay'), findsOneWidget);

    expect(find.text('Chia sẻ ngay'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
