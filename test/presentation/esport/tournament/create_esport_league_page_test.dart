import 'dart:async';
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/round_robin_scheduler.dart';
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

Future<Map<String, MemberInfo>> _stubNameLoader(List<String> ids) async => {
  for (final id in ids) id: (name: id, photoUrl: null),
};

Widget _wrap({
  required List<GNEsportGroup> groups,
  required OnAddLeagueCallback onAddLeague,
}) => MaterialApp(
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
    home: Builder(
      builder: (ctx) {
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
      },
    ),
  );
}

OnAddLeagueCallback _noopCallback() =>
    ({
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

Future<void> _driveToFinalStep(
  WidgetTester tester,
  OnAddLeagueCallback onAddLeague,
) async {
  await tester.pumpWidget(
    _wrap(
      groups: [
        _group('g1', 'Nhóm 1', members: ['p1', 'p2']),
      ],
      onAddLeague: onAddLeague,
    ),
  );
  await _navigateToFinalStep(tester);
}

Future<void> _navigateToFinalStep(WidgetTester tester) async {
  await tester.tap(find.text('Nhóm 1'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('p1'));
  await tester.tap(find.text('p2'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextField, 'Tên giải đấu'),
    'Giải chờ xử lý',
  );
  await tester.pump();
}

OnAddLeagueCallback _pendingCallback(
  Completer<String> completer, {
  VoidCallback? onCalled,
}) =>
    ({
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
    }) {
      onCalled?.call();
      return completer.future;
    };

void main() {
  group('CreateEsportLeaguePage — wizard', () {
    testWidgets('groups rỗng → hiện empty state, nút Tiếp theo disabled', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(groups: [], onAddLeague: _noopCallback()));

      expect(find.text('Bạn chưa tham gia nhóm nào'), findsOneWidget);
      final btn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Tiếp theo'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('chỉ 1 group → auto chọn, nút Tiếp theo enabled', (
      tester,
    ) async {
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
        _wrap(groups: [_group('g1', 'Nhóm 1')], onAddLeague: _noopCallback()),
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
        _wrap(groups: [_group('g1', 'Nhóm 1')], onAddLeague: _noopCallback()),
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
          groups: [
            _group('g1', 'Nhóm 1', members: ['p1', 'p2']),
          ],
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
          groups: [
            _group('g1', 'Nhóm 1', members: ['owner', 'p1', 'p2']),
          ],
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
      final groups = [
        _group('g1', 'Nhóm 1', members: ['p1', 'p2', 'p3', 'p4']),
      ];
      await tester.pumpWidget(
        _wrap(groups: groups, onAddLeague: _noopCallback()),
      );

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
        final groups = [
          _group('g1', 'Nhóm 1', members: ['p1', 'p2', 'p3', 'p4']),
        ];
        await tester.pumpWidget(
          _wrap(groups: groups, onAddLeague: _noopCallback()),
        );

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
        expect(
          find.byIcon(Icons.check_circle),
          findsOneWidget,
          reason: 'Cup bị disable → mode không đổi sang Cup',
        );

        // Tap Full cũng vô hiệu.
        await tester.tap(find.text('Full'));
        await tester.pumpAndSettle();
        expect(
          find.byIcon(Icons.check_circle),
          findsOneWidget,
          reason: 'Full bị disable → mode không đổi sang Full',
        );
      },
    );

    testWidgets('chọn mode League → callback nhận mode=league', (tester) async {
      final captured = _Captured();
      final groups = [
        _group('g1', 'Nhóm 1', members: ['p1', 'p2']),
      ];
      await tester.pumpWidget(
        _wrap(
          groups: groups,
          onAddLeague:
              ({
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

    testWidgets('tạo thành công → page pop với leagueId trả về', (
      tester,
    ) async {
      final popResult = ValueNotifier<String?>(null);
      final groups = [
        _group('g1', 'Nhóm 1', members: ['p1', 'p2']),
      ];
      await tester.pumpWidget(
        _wrapWithNav(
          groups: groups,
          onAddLeague:
              ({
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
        ),
      );

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
      await tester.enterText(
        find.widgetWithText(TextField, 'Tên giải đấu'),
        'Giải test',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Tạo giải đấu'));
      await tester.pumpAndSettle();

      expect(popResult.value, 'created-id');
    });

    testWidgets('step 5 chưa nhập tên → nút Tạo giải đấu disabled', (
      tester,
    ) async {
      final groups = [
        _group('g1', 'Nhóm 1', members: ['p1', 'p2']),
      ];
      await tester.pumpWidget(
        _wrap(groups: groups, onAddLeague: _noopCallback()),
      );

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
      final groups = [
        _group('g1', 'Nhóm 1', members: ['p1', 'p2']),
      ];
      await tester.pumpWidget(
        _wrap(groups: groups, onAddLeague: _noopCallback()),
      );

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

      await tester.enterText(
        find.widgetWithText(TextField, 'Tên giải đấu'),
        'Giải test',
      );
      await tester.pump();

      final btn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Tạo giải đấu'),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('step 5 hiện nút Tạo giải đấu (không phải Tiếp theo)', (
      tester,
    ) async {
      final groups = [
        _group('g1', 'Nhóm 1', members: ['p1', 'p2']),
      ];
      await tester.pumpWidget(
        _wrap(groups: groups, onAddLeague: _noopCallback()),
      );

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

  group('tạo giải trong khi pending', () {
    late List<String> toasts;

    setUp(() {
      toasts = [];
      setShowToastImpl(
        (message, {gravity = ToastGravity.BOTTOM}) => toasts.add(message),
      );
    });

    tearDown(resetShowToast);

    testWidgets(
      'pending hiển thị loading, khóa wizard và chỉ gọi callback một lần',
      (tester) async {
        final completer = Completer<String>();
        var calls = 0;
        await _driveToFinalStep(
          tester,
          _pendingCallback(completer, onCalled: () => calls++),
        );
        final createButton = find.widgetWithText(FilledButton, 'Tạo giải đấu');
        final buttonSize = tester.getSize(createButton);
        final nameInput = tester.widget<EditableText>(
          find.descendant(
            of: find.widgetWithText(TextField, 'Tên giải đấu'),
            matching: find.byType(EditableText),
          ),
        );
        expect(nameInput.focusNode.hasFocus, isTrue);

        await tester.tap(createButton);
        await tester.pump();

        expect(find.text('Đang tạo giải…'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(tester.getSize(find.byType(FilledButton)), buttonSize);
        expect(calls, 1);
        expect(toasts, isEmpty);

        tester.testTextInput.enterText('Tên không được đổi khi đang tạo');
        await tester.pump();
        expect(
          tester
              .widget<TextField>(find.widgetWithText(TextField, 'Tên giải đấu'))
              .controller!
              .text,
          'Giải chờ xử lý',
        );

        final semanticsHandle = tester.ensureSemantics();
        final loadingButtonSemantics = tester.getSemantics(
          find.text('Đang tạo giải…'),
        );
        expect(loadingButtonSemantics.label, 'Đang tạo giải…');
        expect(loadingButtonSemantics.flagsCollection.isButton, isTrue);
        expect(
          loadingButtonSemantics.flagsCollection.isEnabled,
          isNot(Tristate.none),
        );
        expect(
          loadingButtonSemantics.flagsCollection.isEnabled,
          Tristate.isFalse,
        );
        expect(
          loadingButtonSemantics.getSemanticsData().hasAction(
            SemanticsAction.tap,
          ),
          isFalse,
        );
        semanticsHandle.dispose();

        await tester.tap(find.text('Đang tạo giải…'));
        await tester.pump();
        expect(calls, 1);

        final closeButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.close),
        );
        final backButton = tester.widget<OutlinedButton>(
          find.byType(OutlinedButton),
        );
        expect(closeButton.onPressed, isNull);
        expect(backButton.onPressed, isNull);

        await tester.tap(
          find.widgetWithText(TextField, 'Tên giải đấu'),
          warnIfMissed: false,
        );
        await tester.pump();
        expect(nameInput.focusNode.hasFocus, isFalse);
        expect(
          tester
              .widget<TextField>(find.widgetWithText(TextField, 'Tên giải đấu'))
              .controller!
              .text,
          'Giải chờ xử lý',
        );
        expect(await tester.binding.handlePopRoute(), isTrue);
        expect(find.text('5/5'), findsOneWidget);
        expect(toasts, isEmpty);
      },
    );

    testWidgets('pending RoundTooLarge khôi phục form và nút tạo', (
      tester,
    ) async {
      final completer = Completer<String>();
      await _driveToFinalStep(tester, _pendingCallback(completer));

      await tester.tap(find.widgetWithText(FilledButton, 'Tạo giải đấu'));
      await tester.pump();
      expect(find.text('Đang tạo giải…'), findsOneWidget);
      completer.completeError(
        RoundTooLargeException(
          participantCount: 33,
          maxParticipants: kMaxRoundRobinParticipants,
        ),
      );
      await tester.pump();

      expect(find.widgetWithText(FilledButton, 'Tạo giải đấu'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Tạo giải đấu'),
            )
            .onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Tên giải đấu'))
            .controller!
            .text,
        'Giải chờ xử lý',
      );
      expect(toasts, [
        'Giải có quá nhiều người chơi để tạo một lượt (tối đa 32).',
      ]);
    });

    testWidgets('pending lỗi chung khôi phục form và nút tạo', (tester) async {
      final completer = Completer<String>();
      await _driveToFinalStep(tester, _pendingCallback(completer));

      await tester.tap(find.widgetWithText(FilledButton, 'Tạo giải đấu'));
      await tester.pump();
      expect(find.text('Đang tạo giải…'), findsOneWidget);
      completer.completeError(Exception('network'));
      await tester.pump();

      expect(find.widgetWithText(FilledButton, 'Tạo giải đấu'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Tạo giải đấu'),
            )
            .onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Tên giải đấu'))
            .controller!
            .text,
        'Giải chờ xử lý',
      );
      expect(toasts, ['Đã xảy ra lỗi']);
    });

    testWidgets(
      'pending thành công pop đúng leagueId không quay lại nhãn thường',
      (tester) async {
        final completer = Completer<String>();
        final popResult = ValueNotifier<String?>(null);
        await tester.pumpWidget(
          _wrapWithNav(
            groups: [
              _group('g1', 'Nhóm 1', members: ['p1', 'p2']),
            ],
            onAddLeague: _pendingCallback(completer),
            popResult: popResult,
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await _navigateToFinalStep(tester);

        await tester.tap(find.widgetWithText(FilledButton, 'Tạo giải đấu'));
        await tester.pump();
        expect(find.text('Đang tạo giải…'), findsOneWidget);
        completer.complete('L1');
        await tester.pump();

        expect(find.widgetWithText(FilledButton, 'Tạo giải đấu'), findsNothing);
        await tester.pumpAndSettle();
        expect(popResult.value, 'L1');
      },
    );
  });

  group('lỗi khi tạo giải', () {
    late List<String> toasts;

    setUp(() {
      toasts = [];
      setShowToastImpl(
        (message, {gravity = ToastGravity.BOTTOM}) => toasts.add(message),
      );
    });

    tearDown(resetShowToast);

    Future<void> driveToSubmit(WidgetTester tester) async {
      await tester.tap(find.text('Nhóm 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('p1'));
      await tester.tap(find.text('p2'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp theo'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Tên giải đấu'),
        'Giải test',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Tạo giải đấu'));
      await tester.pumpAndSettle();
    }

    OnAddLeagueCallback throwing(Object error) =>
        ({
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
          throw error;
        };

    testWidgets('quá giới hạn người chơi → toast đã dịch, wizard không đóng', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          groups: [
            _group('g1', 'Nhóm 1', members: ['p1', 'p2']),
          ],
          onAddLeague: throwing(
            RoundTooLargeException(
              participantCount: 33,
              maxParticipants: kMaxRoundRobinParticipants,
            ),
          ),
        ),
      );

      await driveToSubmit(tester);

      expect(toasts.single, contains('32'));
      expect(toasts.single, isNot(contains('RoundTooLargeException')));
      expect(find.widgetWithText(FilledButton, 'Tạo giải đấu'), findsOneWidget);
    });

    testWidgets('lỗi bất kỳ khi tạo giải → toast lỗi, wizard không đóng', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          groups: [
            _group('g1', 'Nhóm 1', members: ['p1', 'p2']),
          ],
          onAddLeague: throwing(Exception('network down')),
        ),
      );

      await driveToSubmit(tester);

      expect(toasts, hasLength(1));
      expect(find.widgetWithText(FilledButton, 'Tạo giải đấu'), findsOneWidget);
    });
  });
}
