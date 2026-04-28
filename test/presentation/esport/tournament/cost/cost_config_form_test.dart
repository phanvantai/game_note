import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/presentation/esport/tournament/cost/cost_config_form.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CostConfigForm — render', () {
    testWidgets('default: switch off + default cost field hiển thị "50"',
        (tester) async {
      await tester.pumpWidget(_wrap(const CostConfigForm()));

      // switch off ⇒ rank payouts field bị ẩn
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('VD: 50, 100, 150 (k VND)'), findsNothing);
      // default cost field show
      expect(find.text('Tiền mặc định mỗi trận (k VND)'), findsOneWidget);
      // controller default text "50"
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

      // hiển thị k
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

      // off → field ẩn
      expect(find.widgetWithText(TextField, '50, 100, 150'), findsNothing);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(find.widgetWithText(TextField, '50, 100, 150'), findsOneWidget);

      // tắt lại
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(find.widgetWithText(TextField, '50, 100, 150'), findsNothing);
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
      expect(result.defaultMatchCost, 50 * 1000); // default "50" × 1000
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

      // rank payouts là TextField đầu tiên (default cost field nằm sau)
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
