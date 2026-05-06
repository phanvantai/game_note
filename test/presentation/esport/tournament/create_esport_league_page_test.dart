import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/presentation/esport/tournament/create_esport_league_page.dart';

GNEsportGroup _group(String id, String name) => GNEsportGroup(
  id: id,
  groupName: name,
  ownerId: 'owner',
  members: const ['owner'],
  description: '',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  status: 'active',
);

class _Captured {
  String? name;
  String? groupId;
  DateTime? startDate;
  DateTime? endDate;
  String? description;
  bool? rankPayoutEnabled;
  List<int>? rankPayouts;
  int? defaultMatchCost;
  int callCount = 0;
}

Widget _wrap({
  required List<GNEsportGroup> groups,
  required OnAddLeagueCallback onAddLeague,
}) => MaterialApp(
  home: CreateEsportLeaguePage(groups: groups, onAddLeague: onAddLeague),
);

void main() {
  group('CreateEsportLeaguePage', () {
    testWidgets('render Scaffold, không có AppBar, có nút "Tạo giải đấu"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          groups: [_group('g1', 'Nhóm 1')],
          onAddLeague: (_, _, _, _, _, _, _, _) {},
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Tạo giải đấu'), findsWidgets);
      expect(find.widgetWithText(FilledButton, 'Tạo giải đấu'), findsOneWidget);
      expect(find.text('Cấu hình chi phí'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsNothing);
    });

    testWidgets('mặc định tắt rank payout (switch off khi mở section)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          groups: [_group('g1', 'Nhóm 1')],
          onAddLeague: (_, _, _, _, _, _, _, _) {},
        ),
      );

      // Expand the cost section.
      await tester.tap(find.text('Cấu hình chi phí'));
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);
    });

    testWidgets('bấm "Tạo" khi chưa chọn nhóm ⇒ không gọi callback', (
      tester,
    ) async {
      final captured = _Captured();
      await tester.pumpWidget(
        _wrap(
          groups: [_group('g1', 'Nhóm 1')],
          onAddLeague:
              (_, _, _, _, _, _, _, _) {
                captured.callCount++;
              },
        ),
      );

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Tạo giải đấu'));
      await tester.tap(find.widgetWithText(FilledButton, 'Tạo giải đấu'));
      await tester.pump();
      expect(captured.callCount, 0);
    });

    testWidgets(
      'fill form + chọn nhóm + bấm "Tạo" ⇒ callback nhận đúng giá trị',
      (tester) async {
        final captured = _Captured();
        final groups = [_group('g1', 'Nhóm 1'), _group('g2', 'Nhóm 2')];
        await tester.pumpWidget(
          _wrap(
            groups: groups,
            onAddLeague:
                (
                  name,
                  groupId,
                  startDate,
                  endDate,
                  description,
                  rankPayoutEnabled,
                  rankPayouts,
                  defaultMatchCost,
                ) {
                  captured.callCount++;
                  captured.name = name;
                  captured.groupId = groupId;
                  captured.startDate = startDate;
                  captured.endDate = endDate;
                  captured.description = description;
                  captured.rankPayoutEnabled = rankPayoutEnabled;
                  captured.rankPayouts = rankPayouts;
                  captured.defaultMatchCost = defaultMatchCost;
                },
          ),
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Tên giải đấu'),
          'Giải mùa xuân',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Mô tả (tuỳ chọn)'),
          'Mô tả ngắn',
        );

        await tester.tap(find.byType(DropdownButtonFormField<GNEsportGroup>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Nhóm 2').last);
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.widgetWithText(FilledButton, 'Tạo giải đấu'));
        await tester.tap(find.widgetWithText(FilledButton, 'Tạo giải đấu'));
        await tester.pump();

        expect(captured.callCount, 1);
        expect(captured.name, 'Giải mùa xuân');
        expect(captured.description, 'Mô tả ngắn');
        expect(captured.groupId, 'g2');
        expect(captured.startDate, isNull);
        expect(captured.endDate, isNull);
        // Cost section collapsed → default values.
        expect(captured.rankPayoutEnabled, isFalse);
        expect(captured.rankPayouts, isEmpty);
        expect(captured.defaultMatchCost, 50000);
      },
    );
  });
}
