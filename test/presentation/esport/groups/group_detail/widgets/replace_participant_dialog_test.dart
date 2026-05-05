import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/widgets/replace_participant_dialog.dart';

class _MockGroupDetailBloc
    extends MockBloc<GroupDetailEvent, GroupDetailState>
    implements GroupDetailBloc {}

class _MockLeagueRepo extends Mock implements EsportLeagueRepository {}

class _FakeGroupDetailEvent extends Fake implements GroupDetailEvent {}

GNUser _user(String id, {String name = '', bool isPlaceholder = false}) =>
    GNUser(
      id: id,
      displayName: name.isNotEmpty ? name : 'User $id',
      phoneNumber: null,
      email: null,
      photoUrl: null,
      role: 'user',
      fcmToken: '',
      isPlaceholder: isPlaceholder,
    );

GNEsportLeagueStat _stat(String userId, {GNUser? user}) => GNEsportLeagueStat(
      id: 'S_$userId',
      userId: userId,
      leagueId: 'L1',
      matchesPlayed: 0,
      goals: 0,
      goalsConceded: 0,
      wins: 0,
      draws: 0,
      losses: 0,
      user: user ?? _user(userId),
    );

GNEsportLeague _league({List<String> participants = const ['p1']}) =>
    GNEsportLeague(
      id: 'L1',
      ownerId: 'owner',
      groupId: 'G1',
      name: 'Test League',
      startDate: DateTime(2026, 1, 1),
      isActive: true,
      description: '',
      participants: participants,
    );

GNEsportGroup _group() => GNEsportGroup(
      id: 'G1',
      groupName: 'Group',
      ownerId: 'owner',
      members: const ['owner', 'p1', 'p2'],
      description: '',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      status: 'active',
    );

// currentUserId = 'owner' → isOwner = true (matches group.ownerId)
GroupDetailState _state({
  ViewStatus replaceParticipantStatus = ViewStatus.initial,
  String? currentUserId = 'owner',
}) =>
    GroupDetailState(
      group: _group(),
      replaceParticipantStatus: replaceParticipantStatus,
      currentUserId: currentUserId,
    );

Widget _wrap({
  required GroupDetailBloc bloc,
  required GNEsportLeague league,
  required List<GNUser> groupMembers,
  required EsportLeagueRepository leagueRepo,
}) {
  return BlocProvider<GroupDetailBloc>.value(
    value: bloc,
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => BlocProvider.value(
                value: bloc,
                child: ReplaceParticipantDialog(
                  league: league,
                  groupMembers: groupMembers,
                  leagueRepository: leagueRepo,
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late _MockGroupDetailBloc bloc;
  late _MockLeagueRepo leagueRepo;

  setUpAll(() {
    registerFallbackValue(_FakeGroupDetailEvent());
  });

  setUp(() {
    setShowToastImpl((msg, {gravity = ToastGravity.BOTTOM}) {});
    TestWidgetsFlutterBinding.ensureInitialized();
    bloc = _MockGroupDetailBloc();
    leagueRepo = _MockLeagueRepo();
  });

  Future<void> openDialog(WidgetTester tester,
      {GNEsportLeague? league, List<GNUser>? members}) async {
    when(() => bloc.state).thenReturn(_state());
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => leagueRepo.getLeagueStats('L1'))
        .thenAnswer((_) async => [_stat('p1'), _stat('p2')]);

    await tester.pumpWidget(_wrap(
      bloc: bloc,
      league: league ?? _league(),
      groupMembers: members ?? [_user('p1'), _user('p2', name: 'Player 2')],
      leagueRepo: leagueRepo,
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('step 1: hiển thị tiêu đề và danh sách participants',
      (tester) async {
    await openDialog(tester);

    expect(find.text('Chọn người cần thay'), findsOneWidget);
    expect(find.text('User p1'), findsOneWidget);
    expect(find.text('User p2'), findsOneWidget);
  });

  testWidgets('step 2: hiển thị sau khi chọn oldUser', (tester) async {
    await openDialog(tester);

    await tester.tap(find.text('User p1'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn người thay thế'), findsOneWidget);
    expect(find.text('Player 2'), findsOneWidget);
    expect(find.text('User p1'), findsNothing);
  });

  testWidgets('step 3: hiển thị xác nhận sau khi chọn newUser', (tester) async {
    await openDialog(tester);

    await tester.tap(find.text('User p1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Player 2'));
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận thay thế'), findsOneWidget);
    expect(find.text('Xác nhận'), findsOneWidget);
  });

  testWidgets('hiện cảnh báo merge khi newUser đã có trong giải', (tester) async {
    await openDialog(
      tester,
      league: _league(participants: ['p1', 'p2']),
    );

    await tester.tap(find.text('User p1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Player 2'));
    await tester.pumpAndSettle();

    expect(
      find.text(
          'Người này đã có trong giải. Thống kê của 2 người sẽ được cộng gộp lại.'),
      findsOneWidget,
    );
  });

  testWidgets('không hiện cảnh báo merge khi newUser chưa có trong giải',
      (tester) async {
    await openDialog(
      tester,
      league: _league(participants: ['p1']),
    );

    await tester.tap(find.text('User p1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Player 2'));
    await tester.pumpAndSettle();

    expect(
      find.text(
          'Người này đã có trong giải. Thống kê của 2 người sẽ được cộng gộp lại.'),
      findsNothing,
    );
  });

  testWidgets('nút Quay lại đưa về bước trước', (tester) async {
    await openDialog(tester);

    await tester.tap(find.text('User p1'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn người thay thế'), findsOneWidget);

    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn người cần thay'), findsOneWidget);
  });

  testWidgets('dispatch ReplaceLeagueParticipant khi bấm Xác nhận',
      (tester) async {
    when(() => bloc.add(any())).thenReturn(null);

    await openDialog(tester);

    await tester.tap(find.text('User p1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Player 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    verify(() => bloc.add(const ReplaceLeagueParticipant(
          leagueId: 'L1',
          oldUserId: 'p1',
          newUserId: 'p2',
        ))).called(1);
  });

  testWidgets('hiển thị loading khi replaceParticipantStatus là loading',
      (tester) async {
    when(() => bloc.state)
        .thenReturn(_state(replaceParticipantStatus: ViewStatus.loading));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => leagueRepo.getLeagueStats('L1'))
        .thenAnswer((_) async => [_stat('p1'), _stat('p2')]);

    await tester.pumpWidget(_wrap(
      bloc: bloc,
      league: _league(),
      groupMembers: [_user('p1'), _user('p2', name: 'Player 2')],
      leagueRepo: leagueRepo,
    ));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
