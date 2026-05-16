import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/presentation/esport/tournament/create_esport_league_page.dart';

GNEsportGroup _group(String id, String name, {List<String>? members}) =>
    GNEsportGroup(
      id: id,
      groupName: name,
      ownerId: 'owner',
      members: members ?? ['owner', 'player1', 'player2', 'player3'],
      description: '',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      status: 'active',
    );

class _Captured {
  String? name;
  String? groupId;
  TournamentMode? mode;
  List<String>? participants;
  int? groupCount;
  int? advanceCount;
  List<String>? knockoutSeeding;
  Map<String, int>? groupAssignment;
  int callCount = 0;
}

Future<Map<String, MemberInfo>> _stubNameLoader(List<String> ids) async =>
    {for (final id in ids) id: (name: id, photoUrl: null)};

Widget _wrap({
  required List<GNEsportGroup> groups,
  required OnAddLeagueCallback onAddLeague,
}) =>
    MaterialApp(
      home: CreateEsportLeaguePage(
        groups: groups,
        onAddLeague: onAddLeague,
        memberNameLoader: _stubNameLoader,
      ),
    );

/// Wrap dalam Navigator agar bisa test pop result.
Widget _wrapWithNav({
  required List<GNEsportGroup> groups,
  required OnAddLeagueCallback onAddLeague,
  required ValueNotifier<String?> popResult,
}) {
  return MaterialApp(
    home: Builder(builder: (ctx) {
      return Scaffold(
        body: ElevatedButton(
          onPressed: () async {
            final result = await Navigator.of(ctx).push<String>(
              MaterialPageRoute(
                builder: (_) => CreateEsportLeaguePage(
                  groups: groups,
                  onAddLeague: onAddLeague,
                  memberNameLoader: _stubNameLoader,
                ),
              ),
            );
            popResult.value = result;
          },
          child: const Text('Open'),
        ),
      );
    }),
  );
}

OnAddLeagueCallback _noopCallback() => ({
      required name,
      required groupId,
      startDate,
      endDate,
      required description,
      required rankPayoutEnabled,
      required rankPayouts,
      required defaultMatchCost,
      required defaultPerGoalEnabled,
      required defaultCostPerGoal,
      required mode,
      required participants,
      required groupCount,
      required advanceCount,
      required knockoutSeeding,
      required groupAssignment,
    }) async => 'test-id';

void main() {
  group('CreateEsportLeaguePage — wizard', () {
    testWidgets('groups rỗng → hiện empty state, nút Tiếp theo disabled', (tester) async {
      await tester.pumpWidget(_wrap(groups: [], onAddLeague: _noopCallback()));

      expect(find.text('Bạn chưa tham gia nhóm nào'), findsOneWidget);
      final btn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Tiếp theo'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('chỉ 1 group → auto chọn, nút Tiếp theo enabled', (tester) async {
      await tester.pumpWidget(
        _wrap(groups: [_group('g1', 'Nhóm 1')], onAddLeague: _noopCallback()),
      );
      await tester.pump();

      final btn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Tiếp theo'),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('hiện step 1: danh sách nhóm + nút Tiếp theo', (tester) async {
      await tester.pumpWidget(
        _wrap(
          groups: [_group('g1', 'Nhóm 1')],
          onAddLeague: _noopCallback(),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      // Step indicator "1/5"
      expect(find.text('1/5'), findsOneWidget);
      // Group card
      expect(find.text('Nhóm 1'), findsOneWidget);
      // Navigation button shows "Tiếp theo" on step 1
      expect(find.widgetWithText(FilledButton, 'Tiếp theo'), findsOneWidget);
    });

    testWidgets('step 1 chưa chọn nhóm → nút Tiếp theo disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          groups: [_group('g1', 'Nhóm 1'), _group('g2', 'Nhóm 2')],
          onAddLeague: _noopCallback(),
        ),
      );

      final btn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Tiếp theo'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('step 1 chọn nhóm → nút Tiếp theo enabled', (tester) async {
      await tester.pumpWidget(
        _wrap(
          groups: [_group('g1', 'Nhóm 1')],
          onAddLeague: _noopCallback(),
        ),
      );

      await tester.tap(find.text('Nhóm 1'));
      await tester.pump();

      final btn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Tiếp theo'),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('step 2 chưa chọn đủ 2 người → nút Tiếp theo disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          groups: [_group('g1', 'Nhóm 1', members: ['p1', 'p2'])],
          onAddLeague: _noopCallback(),
        ),
      );

      await tester.tap(find.text('Nhóm 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      // Chọn 1 người
      await tester.tap(find.text('p1'));
      await tester.pump();

      final btn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Tiếp theo'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('chọn nhóm → Tiếp theo → step 2 hiện danh sách members', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          groups: [_group('g1', 'Nhóm 1', members: ['owner', 'p1', 'p2'])],
          onAddLeague: _noopCallback(),
        ),
      );

      // Chọn nhóm
      await tester.tap(find.text('Nhóm 1'));
      await tester.pumpAndSettle();

      // Sang step 2
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      expect(find.text('2/5'), findsOneWidget);
    });

    testWidgets('step 3 hiện 3 mode cards', (tester) async {
      final groups = [_group('g1', 'Nhóm 1', members: ['p1', 'p2', 'p3', 'p4'])];
      await tester.pumpWidget(_wrap(groups: groups, onAddLeague: _noopCallback()));

      // Step 1: chọn nhóm
      await tester.tap(find.text('Nhóm 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      // Step 2: chọn players
      await tester.tap(find.text('p1'));
      await tester.tap(find.text('p2'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      // Step 3
      expect(find.text('3/5'), findsOneWidget);
      expect(find.text('League'), findsOneWidget);
      expect(find.text('Cup'), findsOneWidget);
      expect(find.text('Full'), findsOneWidget);
    });

    testWidgets(
        'step 3: Cup và Full có badge "Sắp ra mắt", tap không đổi mode',
        (tester) async {
      // Tạm thời tắt 2 mode này — chỉ cho phép tạo league cho tới khi
      // luồng cup/full ổn định. Bài test này đứng gác để khi ai bật lại
      // phải xoá comingSoon flag và update lại assertion.
      final groups = [_group('g1', 'Nhóm 1', members: ['p1', 'p2', 'p3', 'p4'])];
      await tester
          .pumpWidget(_wrap(groups: groups, onAddLeague: _noopCallback()));

      // → step 3
      await tester.tap(find.text('Nhóm 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('p1'));
      await tester.tap(find.text('p2'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      // Badge "Sắp ra mắt" xuất hiện đúng 2 lần (Cup + Full).
      expect(find.text('Sắp ra mắt'), findsNWidgets(2));

      // Selected indicator (check_circle) ban đầu chỉ ở mode League
      // (default selected). Tap Cup không được phép → không có thêm tick.
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      await tester.tap(find.text('Cup'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle), findsOneWidget,
          reason: 'Cup bị disable → mode không đổi sang Cup');

      // Tap Full cũng vô hiệu.
      await tester.tap(find.text('Full'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle), findsOneWidget,
          reason: 'Full bị disable → mode không đổi sang Full');
    });

    testWidgets('chọn mode League → callback nhận mode=league', (tester) async {
      final captured = _Captured();
      final groups = [_group('g1', 'Nhóm 1', members: ['p1', 'p2'])];
      await tester.pumpWidget(
        _wrap(
          groups: groups,
          onAddLeague: ({
            required name,
            required groupId,
            startDate,
            endDate,
            required description,
            required rankPayoutEnabled,
            required rankPayouts,
            required defaultMatchCost,
            required defaultPerGoalEnabled,
            required defaultCostPerGoal,
            required mode,
            required participants,
            required groupCount,
            required advanceCount,
            required knockoutSeeding,
            required groupAssignment,
          }) async {
            captured.callCount++;
            captured.name = name;
            captured.groupId = groupId;
            captured.mode = mode;
            captured.participants = participants;
            captured.knockoutSeeding = knockoutSeeding;
            captured.groupAssignment = groupAssignment;
            return 'test-id';
          },
        ),
      );

      // Step 1
      await tester.tap(find.text('Nhóm 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      // Step 2: chọn 2 players
      await tester.tap(find.text('p1'));
      await tester.tap(find.text('p2'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      // Step 3: League đã được chọn mặc định → tiếp theo
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      // Step 4: config & preview → tiếp theo
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      // Step 5: nhập tên
      await tester.enterText(
        find.widgetWithText(TextField, 'Tên giải đấu'),
        'Giải test',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Tạo giải đấu'));
      await tester.pump();

      expect(captured.callCount, 1);
      expect(captured.name, 'Giải test');
      expect(captured.groupId, 'g1');
      expect(captured.mode, TournamentMode.league);
      expect(captured.participants, containsAll(['p1', 'p2']));
      expect(captured.knockoutSeeding, isEmpty);
      expect(captured.groupAssignment, isEmpty);
    });

    testWidgets('tạo thành công → page pop với leagueId trả về', (tester) async {
      final popResult = ValueNotifier<String?>(null);
      final groups = [_group('g1', 'Nhóm 1', members: ['p1', 'p2'])];
      await tester.pumpWidget(_wrapWithNav(
        groups: groups,
        onAddLeague: ({
          required name,
          required groupId,
          startDate,
          endDate,
          required description,
          required rankPayoutEnabled,
          required rankPayouts,
          required defaultMatchCost,
          required defaultPerGoalEnabled,
          required defaultCostPerGoal,
          required mode,
          required participants,
          required groupCount,
          required advanceCount,
          required knockoutSeeding,
          required groupAssignment,
        }) async => 'created-id',
        popResult: popResult,
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Step 1
      await tester.tap(find.text('Nhóm 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      // Step 2
      await tester.tap(find.text('p1'));
      await tester.tap(find.text('p2'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      // Step 3: mode selection
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      // Step 4: config & preview
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      // Step 5: info
      await tester.enterText(find.widgetWithText(TextField, 'Tên giải đấu'), 'Giải test');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Tạo giải đấu'));
      await tester.pumpAndSettle();

      expect(popResult.value, 'created-id');
    });

    testWidgets('step 5 chưa nhập tên → nút Tạo giải đấu disabled', (tester) async {
      final groups = [_group('g1', 'Nhóm 1', members: ['p1', 'p2'])];
      await tester.pumpWidget(_wrap(groups: groups, onAddLeague: _noopCallback()));

      await tester.tap(find.text('Nhóm 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('p1'));
      await tester.tap(find.text('p2'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();
      // Step 3 → step 4 (config)
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();
      // Step 4 → step 5 (info)
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      final btn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Tạo giải đấu'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('step 5 nhập tên → nút Tạo giải đấu enabled', (tester) async {
      final groups = [_group('g1', 'Nhóm 1', members: ['p1', 'p2'])];
      await tester.pumpWidget(_wrap(groups: groups, onAddLeague: _noopCallback()));

      await tester.tap(find.text('Nhóm 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('p1'));
      await tester.tap(find.text('p2'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();
      // Step 3 → 4
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();
      // Step 4 → 5
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Tên giải đấu'), 'Giải test');
      await tester.pump();

      final btn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Tạo giải đấu'),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('step 5 hiện nút Tạo giải đấu (không phải Tiếp theo)', (
      tester,
    ) async {
      final groups = [_group('g1', 'Nhóm 1', members: ['p1', 'p2'])];
      await tester.pumpWidget(_wrap(groups: groups, onAddLeague: _noopCallback()));

      // Navigate through all steps
      await tester.tap(find.text('Nhóm 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('p1'));
      await tester.tap(find.text('p2'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      // Step 3 → 4
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      // Step 4 → 5
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      // Step 5
      expect(find.text('5/5'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Tạo giải đấu'), findsOneWidget);
      expect(find.text('Cấu hình chi phí'), findsOneWidget);
    });
  });
}
