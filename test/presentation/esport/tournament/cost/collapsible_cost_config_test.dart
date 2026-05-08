import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/presentation/esport/tournament/cost/collapsible_cost_config.dart';
import 'package:pes_arena/presentation/esport/tournament/cost/cost_config_form.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('CollapsibleCostConfig — trạng thái mặc định', () {
    testWidgets('header luôn hiển thị', (tester) async {
      final formKey = GlobalKey<CostConfigFormState>();
      await tester.pumpWidget(_wrap(
        CollapsibleCostConfig(formKey: formKey, participantCount: 4),
      ));

      expect(find.text('Cấu hình chi phí'), findsOneWidget);
    });

    testWidgets('icon mũi tên không xoay khi đang thu gọn', (tester) async {
      final formKey = GlobalKey<CostConfigFormState>();
      await tester.pumpWidget(_wrap(
        CollapsibleCostConfig(formKey: formKey, participantCount: 4),
      ));

      // AnimatedRotation starts at turns=0 when collapsed
      final rotation = tester.widget<AnimatedRotation>(
        find.byType(AnimatedRotation),
      );
      expect(rotation.turns, 0.0);
    });

    testWidgets('hiển thị subtitle khi thu gọn nếu có subtitle', (tester) async {
      final formKey = GlobalKey<CostConfigFormState>();
      await tester.pumpWidget(_wrap(
        CollapsibleCostConfig(
          formKey: formKey,
          subtitle: 'Tổng: 200k',
          participantCount: 4,
        ),
      ));

      expect(find.text('Tổng: 200k'), findsOneWidget);
    });

    testWidgets('form không tương tác được khi đang thu gọn', (tester) async {
      final formKey = GlobalKey<CostConfigFormState>();
      await tester.pumpWidget(_wrap(
        CollapsibleCostConfig(formKey: formKey, participantCount: 4),
      ));

      // CostConfigForm is in the tree (AnimatedCrossFade keeps both children)
      // but should not be hitTestable when collapsed
      expect(find.byType(CostConfigForm).hitTestable(), findsNothing);
    });
  });

  group('CollapsibleCostConfig — expand/collapse', () {
    testWidgets('tap header → mở rộng và form trở nên tương tác được', (tester) async {
      final formKey = GlobalKey<CostConfigFormState>();
      await tester.pumpWidget(_wrap(
        CollapsibleCostConfig(formKey: formKey, participantCount: 4),
      ));

      await tester.tap(find.text('Cấu hình chi phí'));
      await tester.pumpAndSettle();

      expect(find.byType(CostConfigForm).hitTestable(), findsOneWidget);
    });

    testWidgets('icon xoay 180° khi mở rộng', (tester) async {
      final formKey = GlobalKey<CostConfigFormState>();
      await tester.pumpWidget(_wrap(
        CollapsibleCostConfig(formKey: formKey, participantCount: 4),
      ));

      await tester.tap(find.text('Cấu hình chi phí'));
      await tester.pumpAndSettle();

      final rotation = tester.widget<AnimatedRotation>(
        find.byType(AnimatedRotation),
      );
      expect(rotation.turns, 0.5);
    });

    testWidgets('tap header lần 2 → thu gọn lại, form không tương tác', (tester) async {
      final formKey = GlobalKey<CostConfigFormState>();
      await tester.pumpWidget(_wrap(
        CollapsibleCostConfig(formKey: formKey, participantCount: 4),
      ));

      await tester.tap(find.text('Cấu hình chi phí'));
      await tester.pumpAndSettle();
      expect(find.byType(CostConfigForm).hitTestable(), findsOneWidget);

      await tester.tap(find.text('Cấu hình chi phí'));
      await tester.pumpAndSettle();
      expect(find.byType(CostConfigForm).hitTestable(), findsNothing);
    });

    testWidgets('subtitle bị ẩn khi đang mở rộng', (tester) async {
      final formKey = GlobalKey<CostConfigFormState>();
      await tester.pumpWidget(_wrap(
        CollapsibleCostConfig(
          formKey: formKey,
          subtitle: 'Tổng: 200k',
          participantCount: 4,
        ),
      ));

      expect(find.text('Tổng: 200k'), findsOneWidget);

      await tester.tap(find.text('Cấu hình chi phí'));
      await tester.pumpAndSettle();

      expect(find.text('Tổng: 200k'), findsNothing);
    });

    testWidgets('action widget hiển thị khi mở rộng', (tester) async {
      final formKey = GlobalKey<CostConfigFormState>();
      await tester.pumpWidget(_wrap(
        CollapsibleCostConfig(
          formKey: formKey,
          participantCount: 4,
          action: const Text('Lưu'),
        ),
      ));

      // Before expand: action is in tree via AnimatedCrossFade but not hitTestable
      expect(find.text('Lưu').hitTestable(), findsNothing);

      await tester.tap(find.text('Cấu hình chi phí'));
      await tester.pumpAndSettle();

      expect(find.text('Lưu').hitTestable(), findsOneWidget);
    });
  });
}
