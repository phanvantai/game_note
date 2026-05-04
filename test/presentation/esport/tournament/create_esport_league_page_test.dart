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
    testWidgets('render Scaffold + AppBar "Tạo giải đấu" + nút "Tạo"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          groups: [_group('g1', 'Nhóm 1')],
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
              ) {},
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Tạo giải đấu'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Tạo'), findsOneWidget);
      // section header chi phí (luôn hiện, không còn ExpansionTile)
      expect(find.text('Chi phí'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsNothing);
    });

    testWidgets('mặc định bật rank payout (switch on + field hiện)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          groups: [_group('g1', 'Nhóm 1')],
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
              ) {},
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
      expect(find.widgetWithText(TextField, '50, 100, 150'), findsOneWidget);
    });

    testWidgets('bấm "Tạo" khi chưa chọn nhóm ⇒ không gọi callback', (
      tester,
    ) async {
      final captured = _Captured();
      await tester.pumpWidget(
        _wrap(
          groups: [_group('g1', 'Nhóm 1')],
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
              },
        ),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Tạo'));
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
          find.widgetWithText(TextField, 'Mô tả'),
          'Mô tả ngắn',
        );

        // mở dropdown + chọn item "Nhóm 2"
        await tester.tap(find.byType(DropdownButtonFormField<GNEsportGroup>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Nhóm 2').last);
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'Tạo'));
        await tester.pump();

        expect(captured.callCount, 1);
        expect(captured.name, 'Giải mùa xuân');
        expect(captured.description, 'Mô tả ngắn');
        expect(captured.groupId, 'g2');
        expect(captured.startDate, isNull);
        expect(captured.endDate, isNull);
        expect(captured.rankPayoutEnabled, isTrue);
        expect(captured.rankPayouts, [50000, 100000, 150000]);
        expect(captured.defaultMatchCost, 50000);
      },
    );
  });
}
