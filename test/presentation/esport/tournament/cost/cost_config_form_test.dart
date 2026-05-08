import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/presentation/esport/tournament/cost/cost_config_form.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('generateRankPayoutPresets', () {
    test('0 người tham gia → rỗng', () {
      expect(generateRankPayoutPresets(0), isEmpty);
    });

    test('1 người tham gia → rỗng', () {
      expect(generateRankPayoutPresets(1), isEmpty);
    });

    test('2 người: 1 slot → 2 preset không trùng', () {
      final presets = generateRankPayoutPresets(2);
      expect(presets, hasLength(2));
      expect(presets[0], [50]);
      expect(presets[1], [100]);
    });

    test('3 người: 2 slots → 3 preset', () {
      final presets = generateRankPayoutPresets(3);
      expect(presets, hasLength(3));
      expect(presets[0], [50, 100]);
      expect(presets[1], [100, 150]);
      expect(presets[2], [100, 200]);
    });

    test('4 người: 3 slots → 3 preset', () {
      final presets = generateRankPayoutPresets(4);
      expect(presets, hasLength(3));
      expect(presets[0], [50, 100, 150]);
      expect(presets[1], [100, 150, 200]);
      expect(presets[2], [100, 200, 300]);
    });

    test('5 người: 4 slots → 3 preset', () {
      final presets = generateRankPayoutPresets(5);
      expect(presets, hasLength(3));
      expect(presets[0], [50, 100, 150, 200]);
      expect(presets[1], [100, 150, 200, 250]);
      expect(presets[2], [100, 200, 300, 400]);
    });

    test('6 người: 5 slots → 3 preset', () {
      final presets = generateRankPayoutPresets(6);
      expect(presets, hasLength(3));
      expect(presets[0], [50, 100, 150, 200, 250]);
      expect(presets[1], [100, 150, 200, 250, 300]);
      expect(presets[2], [100, 200, 300, 400, 500]);
    });

    test('không có preset trùng nhau', () {
      for (final n in [2, 3, 4, 5, 6, 8, 10]) {
        final presets = generateRankPayoutPresets(n);
        final keys = presets.map((p) => p.join(',')).toList();
        expect(keys.toSet().length, keys.length, reason: 'n=$n có preset trùng');
      }
    });

    test('mỗi preset có đúng (participantCount - 1) phần tử', () {
      for (final n in [2, 3, 4, 5, 6]) {
        final presets = generateRankPayoutPresets(n);
        for (final p in presets) {
          expect(p.length, n - 1, reason: 'n=$n, preset=$p');
        }
      }
    });

    test('mọi giá trị trong preset đều dương', () {
      for (final n in [2, 3, 4, 5, 6, 10]) {
        final presets = generateRankPayoutPresets(n);
        for (final p in presets) {
          expect(p.every((v) => v > 0), isTrue, reason: 'n=$n, preset=$p');
        }
      }
    });
  });

  group('CostConfigForm — render', () {
    testWidgets('default: switch off + default cost field hiển thị "50"',
        (tester) async {
      await tester.pumpWidget(_wrap(const CostConfigForm()));

      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('VD: 50, 100, 150 (k VND)'), findsNothing);
      expect(find.text('Tiền mặc định mỗi trận (k VND)'), findsOneWidget);
      expect(find.widgetWithText(TextField, '50'), findsOneWidget);
    });

    testWidgets('initialDefaultMatchCost: 80000 VND ⇒ field hiện "80"',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const CostConfigForm(initialDefaultMatchCost: 80000)),
      );
      expect(find.widgetWithText(TextField, '80'), findsOneWidget);
    });

    testWidgets('initialRankPayoutEnabled = true ⇒ field rank payouts hiện',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const CostConfigForm(
          initialRankPayoutEnabled: true,
          initialRankPayouts: [50000, 100000, 150000],
        )),
      );
      expect(find.widgetWithText(TextField, '50, 100, 150'), findsOneWidget);
    });

    testWidgets(
        'initialRankPayoutEnabled = true + rỗng ⇒ placeholder "50, 100, 150"',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const CostConfigForm(initialRankPayoutEnabled: true)),
      );
      expect(find.widgetWithText(TextField, '50, 100, 150'), findsOneWidget);
    });

    testWidgets('toggle switch ⇒ rank payouts field xuất hiện/ẩn',
        (tester) async {
      await tester.pumpWidget(_wrap(const CostConfigForm()));

      expect(find.widgetWithText(TextField, '50, 100, 150'), findsNothing);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(find.widgetWithText(TextField, '50, 100, 150'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(find.widgetWithText(TextField, '50, 100, 150'), findsNothing);
    });

    testWidgets(
        'rank payouts field: inputFormatter chỉ cho số, dấu phẩy, khoảng trắng',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const CostConfigForm(initialRankPayoutEnabled: true)),
      );

      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, '50, 100, 150'),
      );
      expect(field.keyboardType, TextInputType.text);
      expect(field.inputFormatters, isNotNull);
      expect(field.inputFormatters!.length, 1);

      final formatter = field.inputFormatters!.first;
      String filter(String raw) => formatter
          .formatEditUpdate(
            TextEditingValue.empty,
            TextEditingValue(text: raw),
          )
          .text;

      expect(filter('50, 100, 150'), '50, 100, 150');
      expect(filter('abc50,100xyz'), '50,100');
      expect(filter('50.5;100'), '505100');
      expect(filter('  20 , 40 '), '  20 , 40 ');
    });
  });

  group('CostConfigForm — preset chips', () {
    testWidgets('participantCount = 0: không hiện chips dù switch on',
        (tester) async {
      await tester.pumpWidget(_wrap(const CostConfigForm(
        initialRankPayoutEnabled: true,
        participantCount: 0,
      )));
      expect(find.byType(ActionChip), findsNothing);
      expect(find.text('Gợi ý:'), findsNothing);
    });

    testWidgets('participantCount = 1: không hiện chips', (tester) async {
      await tester.pumpWidget(_wrap(const CostConfigForm(
        initialRankPayoutEnabled: true,
        participantCount: 1,
      )));
      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets('participantCount = 2: 2 chips khi switch on', (tester) async {
      await tester.pumpWidget(_wrap(const CostConfigForm(
        initialRankPayoutEnabled: true,
        participantCount: 2,
      )));
      expect(find.byType(ActionChip), findsNWidgets(2));
      expect(find.text('Gợi ý:'), findsOneWidget);
    });

    testWidgets('participantCount = 4: 3 chips khi switch on', (tester) async {
      await tester.pumpWidget(_wrap(const CostConfigForm(
        initialRankPayoutEnabled: true,
        participantCount: 4,
      )));
      expect(find.byType(ActionChip), findsNWidgets(3));
    });

    testWidgets('participantCount = 5: 3 chips khi switch on', (tester) async {
      await tester.pumpWidget(_wrap(const CostConfigForm(
        initialRankPayoutEnabled: true,
        participantCount: 5,
      )));
      expect(find.byType(ActionChip), findsNWidgets(3));
      expect(find.text('50, 100, 150, 200 k'), findsOneWidget);
      expect(find.text('100, 150, 200, 250 k'), findsOneWidget);
      expect(find.text('100, 200, 300, 400 k'), findsOneWidget);
    });

    testWidgets('switch off ⇒ chips ẩn dù participantCount > 1',
        (tester) async {
      await tester.pumpWidget(_wrap(const CostConfigForm(
        initialRankPayoutEnabled: false,
        participantCount: 5,
      )));
      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets('tap chip → điền giá trị vào text field (không có "k")',
        (tester) async {
      final key = GlobalKey<CostConfigFormState>();
      await tester.pumpWidget(_wrap(CostConfigForm(
        key: key,
        initialRankPayoutEnabled: true,
        participantCount: 4,
      )));

      await tester.tap(find.text('50, 100, 150 k'));
      await tester.pump();

      expect(
        find.widgetWithText(TextField, '50, 100, 150'),
        findsOneWidget,
      );
    });

    testWidgets('tap chip thứ hai → text field cập nhật đúng', (tester) async {
      final key = GlobalKey<CostConfigFormState>();
      await tester.pumpWidget(_wrap(CostConfigForm(
        key: key,
        initialRankPayoutEnabled: true,
        participantCount: 4,
      )));

      await tester.tap(find.text('100, 150, 200 k'));
      await tester.pump();

      expect(
        find.widgetWithText(TextField, '100, 150, 200'),
        findsOneWidget,
      );
    });

    testWidgets('tap chip → validateAndCollect trả đúng giá trị k×1000',
        (tester) async {
      final key = GlobalKey<CostConfigFormState>();
      await tester.pumpWidget(_wrap(CostConfigForm(
        key: key,
        initialRankPayoutEnabled: true,
        participantCount: 4,
      )));

      await tester.tap(find.text('100, 200, 300 k'));
      await tester.pump();

      final result = key.currentState!.validateAndCollect();
      expect(result, isNotNull);
      expect(result!.rankPayouts, [100000, 200000, 300000]);
    });

    testWidgets('chips chỉ hiện sau khi bật switch', (tester) async {
      await tester.pumpWidget(_wrap(const CostConfigForm(
        initialRankPayoutEnabled: false,
        participantCount: 4,
      )));

      expect(find.byType(ActionChip), findsNothing);

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(find.byType(ActionChip), findsNWidgets(3));
    });
  });

  group('CostConfigForm — bracket mode', () {
    testWidgets('isBracketMode: switch label bracket, không có preset chips',
        (tester) async {
      await tester.pumpWidget(_wrap(const CostConfigForm(
        isBracketMode: true,
        initialRankPayoutEnabled: true,
        participantCount: 4,
      )));

      expect(find.text('Tính tiền theo bracket'), findsOneWidget);
      expect(find.text('Tính tiền theo thứ hạng'), findsNothing);
      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets('isBracketMode: description text bracket khi switch on',
        (tester) async {
      await tester.pumpWidget(_wrap(const CostConfigForm(
        isBracketMode: true,
        initialRankPayoutEnabled: true,
      )));

      expect(
        find.textContaining('runner-up'),
        findsWidgets,
      );
      expect(
        find.textContaining('hạng 2, hạng 3'),
        findsNothing,
      );
    });

    testWidgets('isBracketMode = false (default): label cũ + preset hiện',
        (tester) async {
      await tester.pumpWidget(_wrap(const CostConfigForm(
        initialRankPayoutEnabled: true,
        participantCount: 4,
      )));

      expect(find.text('Tính tiền theo thứ hạng'), findsOneWidget);
      expect(find.byType(ActionChip), findsNWidgets(3));
    });
  });

  group('CostConfigForm — validateAndCollect', () {
    testWidgets('disabled: rankPayouts rỗng, dùng default match cost từ field',
        (tester) async {
      final key = GlobalKey<CostConfigFormState>();
      await tester.pumpWidget(_wrap(CostConfigForm(key: key)));

      final result = key.currentState!.validateAndCollect();
      expect(result, isNotNull);
      expect(result!.rankPayoutEnabled, isFalse);
      expect(result.rankPayouts, isEmpty);
      expect(result.defaultMatchCost, 50 * 1000);
    });

    testWidgets('enabled + valid input ⇒ parse + nhân 1000', (tester) async {
      final key = GlobalKey<CostConfigFormState>();
      await tester.pumpWidget(_wrap(CostConfigForm(
        key: key,
        initialRankPayoutEnabled: true,
        initialRankPayouts: [30000, 60000],
        initialDefaultMatchCost: 70000,
      )));

      final result = key.currentState!.validateAndCollect();
      expect(result, isNotNull);
      expect(result!.rankPayoutEnabled, isTrue);
      expect(result.rankPayouts, [30000, 60000]);
      expect(result.defaultMatchCost, 70000);
    });

    testWidgets('enabled + input rỗng ⇒ null (validation fail)',
        (tester) async {
      final key = GlobalKey<CostConfigFormState>();
      await tester.pumpWidget(_wrap(CostConfigForm(
        key: key,
        initialRankPayoutEnabled: true,
        initialRankPayouts: const [50000],
      )));

      await tester.enterText(find.byType(TextField).first, '');
      final result = key.currentState!.validateAndCollect();
      expect(result, isNull);
    });

    testWidgets('parser bỏ token rỗng/zero, nhân 1000', (tester) async {
      final key = GlobalKey<CostConfigFormState>();
      await tester.pumpWidget(_wrap(CostConfigForm(
        key: key,
        initialRankPayoutEnabled: true,
      )));

      await tester.enterText(
        find.widgetWithText(TextField, '50, 100, 150'),
        '  20 , , 0, 40 ,abc, 60',
      );
      final result = key.currentState!.validateAndCollect();
      expect(result!.rankPayouts, [20000, 40000, 60000]);
    });

    testWidgets('default cost field rỗng ⇒ fallback 50k', (tester) async {
      final key = GlobalKey<CostConfigFormState>();
      await tester.pumpWidget(_wrap(CostConfigForm(key: key)));

      await tester.enterText(find.widgetWithText(TextField, '50'), '');
      final result = key.currentState!.validateAndCollect();
      expect(result!.defaultMatchCost, 50000);
    });

    testWidgets('default cost field nhập "75" ⇒ 75000', (tester) async {
      final key = GlobalKey<CostConfigFormState>();
      await tester.pumpWidget(_wrap(CostConfigForm(key: key)));

      await tester.enterText(find.widgetWithText(TextField, '50'), '75');
      final result = key.currentState!.validateAndCollect();
      expect(result!.defaultMatchCost, 75000);
    });
  });
}
