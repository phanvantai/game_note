import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/widgets/group_leagues_tab.dart';

class _MockGroupDetailBloc
    extends MockBloc<GroupDetailEvent, GroupDetailState>
    implements GroupDetailBloc {}

class _FakeGroupDetailEvent extends Fake implements GroupDetailEvent {}

GNEsportGroup _group() => GNEsportGroup(
      id: 'G1',
      groupName: 'Test Group',
      ownerId: 'owner1',
      members: const ['owner1'],
      description: '',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      status: 'active',
    );

GNEsportLeague _league(String id) => GNEsportLeague(
      id: id,
      ownerId: 'owner1',
      groupId: 'G1',
      name: 'League $id',
      startDate: DateTime(2026, 1, 1),
      isActive: true,
      description: '',
      participants: const ['p1', 'p2'],
      status: 'ongoing',
    );

// currentUserId = 'owner1' → isOwner = true (group.ownerId == currentUserId)
// currentUserId = null     → isOwner = false
GroupDetailState _state({
  ViewStatus leaguesStatus = ViewStatus.initial,
  List<GNEsportLeague> leagues = const [],
  String? currentUserId,
  List<GNUser> members = const [],
}) {
  return GroupDetailState(
    group: _group(),
    leaguesStatus: leaguesStatus,
    leagues: leagues,
    currentUserId: currentUserId,
    members: members,
  );
}

Widget _wrap(GroupDetailBloc bloc, {GoRouter? router}) {
  final r = router ??
      GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: GroupLeaguesTab()),
        ),
        GoRoute(path: '/tournament/:leagueId', builder: (_, _) => const SizedBox()),
      ]);
  return BlocProvider<GroupDetailBloc>.value(
    value: bloc,
    child: MaterialApp.router(routerConfig: r),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeGroupDetailEvent());
  });

  setUp(() {
    setShowToastImpl((msg, {gravity = ToastGravity.BOTTOM}) {});
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('hiển thị loading indicator khi leaguesStatus là loading',
      (tester) async {
    final bloc = _MockGroupDetailBloc();
    when(() => bloc.state).thenReturn(_state(leaguesStatus: ViewStatus.loading));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('hiển thị text trống khi leagues rỗng và không loading',
      (tester) async {
    final bloc = _MockGroupDetailBloc();
    when(() => bloc.state).thenReturn(
        _state(leaguesStatus: ViewStatus.success, leagues: const []));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc));

    expect(find.text('Chưa có giải đấu nào'), findsOneWidget);
  });

  testWidgets('hiển thị danh sách giải khi có leagues', (tester) async {
    final bloc = _MockGroupDetailBloc();
    when(() => bloc.state).thenReturn(_state(
      leaguesStatus: ViewStatus.success,
      leagues: [_league('L1'), _league('L2')],
    ));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc));

    expect(find.text('League L1'), findsOneWidget);
    expect(find.text('League L2'), findsOneWidget);
  });

  testWidgets('nút Quản lý hiển thị khi isOwner = true', (tester) async {
    final bloc = _MockGroupDetailBloc();
    when(() => bloc.state).thenReturn(_state(
      leaguesStatus: ViewStatus.success,
      leagues: [_league('L1')],
      currentUserId: 'owner1', // matches group.ownerId
    ));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc));

    expect(find.byTooltip('Quản lý người chơi'), findsOneWidget);
  });

  testWidgets('nút Quản lý không hiển thị khi isOwner = false', (tester) async {
    final bloc = _MockGroupDetailBloc();
    when(() => bloc.state).thenReturn(_state(
      leaguesStatus: ViewStatus.success,
      leagues: [_league('L1')],
      currentUserId: null, // no user logged in → not owner
    ));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc));

    expect(find.byTooltip('Quản lý người chơi'), findsNothing);
  });

  testWidgets('chip Đã xoá hiển thị khi isActive = false', (tester) async {
    final bloc = _MockGroupDetailBloc();
    when(() => bloc.state).thenReturn(_state(
      leaguesStatus: ViewStatus.success,
      leagues: [_league('L1').copyWith(isActive: false)],
    ));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc));

    expect(find.text('Đã xoá'), findsOneWidget);
  });

  testWidgets('chip Đã xoá không hiển thị khi isActive = true', (tester) async {
    final bloc = _MockGroupDetailBloc();
    when(() => bloc.state).thenReturn(_state(
      leaguesStatus: ViewStatus.success,
      leagues: [_league('L1')],
    ));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc));

    expect(find.text('Đã xoá'), findsNothing);
  });

  testWidgets('badge Đã xử lý hiển thị khi mergeCompleted = true', (tester) async {
    final bloc = _MockGroupDetailBloc();
    when(() => bloc.state).thenReturn(_state(
      leaguesStatus: ViewStatus.success,
      leagues: [_league('L1').copyWith(mergeCompleted: true)],
    ));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc));

    expect(find.text('Đã xử lý'), findsOneWidget);
  });

  testWidgets('badge Đã xử lý không hiển thị khi mergeCompleted = false',
      (tester) async {
    final bloc = _MockGroupDetailBloc();
    when(() => bloc.state).thenReturn(_state(
      leaguesStatus: ViewStatus.success,
      leagues: [_league('L1')],
    ));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc));

    expect(find.text('Đã xử lý'), findsNothing);
  });

  testWidgets('nút toggle dispatch SetLeagueMergeCompleted khi bấm',
      (tester) async {
    final bloc = _MockGroupDetailBloc();
    when(() => bloc.state).thenReturn(_state(
      leaguesStatus: ViewStatus.success,
      leagues: [_league('L1')],
      currentUserId: 'owner1',
    ));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => bloc.add(any())).thenReturn(null);

    await tester.pumpWidget(_wrap(bloc));
    await tester.tap(find.byTooltip('Đánh dấu đã xử lý merge'));
    await tester.pumpAndSettle();

    verify(() => bloc.add(const SetLeagueMergeCompleted(
          leagueId: 'L1',
          completed: true,
        ))).called(1);
  });

  testWidgets('tap vào league card navigate tới tournament detail', (tester) async {
    final bloc = _MockGroupDetailBloc();
    when(() => bloc.state).thenReturn(_state(
      leaguesStatus: ViewStatus.success,
      leagues: [_league('L1')],
    ));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    String? navigatedPath;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: GroupLeaguesTab()),
        ),
        GoRoute(
          path: '/tournament/:leagueId',
          builder: (context, state) {
            navigatedPath = state.pathParameters['leagueId'];
            return const SizedBox();
          },
        ),
      ],
    );

    await tester.pumpWidget(_wrap(bloc, router: router));
    await tester.tap(find.text('League L1'));
    await tester.pumpAndSettle();

    expect(navigatedPath, 'L1');
  });
}
