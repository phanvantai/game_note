import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/presentation/esport/tournament/create_esport_league_page.dart';
import 'package:pes_arena/presentation/esport/groups/bloc/group_bloc.dart';
import 'package:pes_arena/presentation/esport/tournament/bloc/tournament_bloc.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_view.dart';

class _MockTournamentBloc extends MockBloc<TournamentEvent, TournamentState>
    implements TournamentBloc {}

class _MockGroupBloc extends MockBloc<GroupEvent, GroupState>
    implements GroupBloc {}

class _MockLeagueRepository extends Mock implements EsportLeagueRepository {}

class _MockFirestore extends Mock implements GNFirestore {}

GNEsportGroup _group(String id, String name) {
  return GNEsportGroup(
    id: id,
    groupName: name,
    ownerId: 'u1',
    members: const ['u1'],
    description: '',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    status: 'active',
  );
}

GNEsportLeague _league(
  String id,
  String name, {
  DateTime? startDate,
  DateTime? endDate,
  bool hasEndDate = true,
  GNEsportGroup? group,
  String? status,
  List<String>? participants,
}) {
  return GNEsportLeague(
    id: id,
    ownerId: 'u1',
    groupId: 'g1',
    name: name,
    startDate: startDate ?? DateTime(2026, 1, 1),
    endDate: hasEndDate ? (endDate ?? DateTime(2026, 1, 31)) : null,
    isActive: true,
    description: 'Season one',
    participants: participants ?? const ['u1', 'u2'],
    status: status ?? GNEsportLeagueStatus.ongoing.value,
    group: group ?? _group('g1', 'Group One'),
  );
}

Widget _wrap({
  required TournamentBloc tournamentBloc,
  required GroupBloc groupBloc,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<TournamentBloc>.value(value: tournamentBloc),
      BlocProvider<GroupBloc>.value(value: groupBloc),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const TournamentView(),
          ),
          GoRoute(
            path: '/tournament/:leagueId',
            builder: (context, state) => Scaffold(
              appBar: AppBar(),
              body: Text('tournament ${state.pathParameters['leagueId']}'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TestGroupState extends GroupState {
  final List<GNEsportGroup> _userGroups;
  final List<GNEsportGroup> _otherGroups;

  const _TestGroupState({
    List<GNEsportGroup> userGroups = const [],
    List<GNEsportGroup> otherGroups = const [],
  }) : _userGroups = userGroups,
       _otherGroups = otherGroups,
       super(viewStatus: ViewStatus.success);

  @override
  List<GNEsportGroup> get userGroups => _userGroups;

  @override
  List<GNEsportGroup> get otherGroups => _otherGroups;
}

GroupState _groupState({
  List<GNEsportGroup> userGroups = const [],
  List<GNEsportGroup> otherGroups = const [],
}) {
  return _TestGroupState(userGroups: userGroups, otherGroups: otherGroups);
}

void _registerCreateDependencies({
  required _MockLeagueRepository leagueRepo,
  required _MockFirestore firestore,
}) {
  final getIt = GetIt.instance;
  if (getIt.isRegistered<EsportLeagueRepository>()) {
    getIt.unregister<EsportLeagueRepository>();
  }
  if (getIt.isRegistered<GNFirestore>()) {
    getIt.unregister<GNFirestore>();
  }
  getIt.registerSingleton<EsportLeagueRepository>(leagueRepo);
  getIt.registerSingleton<GNFirestore>(firestore);
}

void _setCreateLeaguePageBuilder({
  required TournamentMode mode,
  List<String> participants = const ['u1', 'u2'],
  int groupCount = 2,
  int advanceCount = 2,
  Map<String, int> groupAssignment = const {'u1': 0, 'u2': 1},
  List<String> knockoutSeeding = const ['A1', 'A2'],
  void Function(Object error, StackTrace stackTrace)? onError,
}) {
  tournamentCreatePageBuilder =
      ({
        required List<GNEsportGroup> groups,
        required OnAddLeagueCallback onAddLeague,
      }) {
        return _SubmitLeaguePage(
          groupId: groups.first.id,
          onAddLeague: onAddLeague,
          mode: mode,
          participants: participants,
          groupCount: groupCount,
          advanceCount: advanceCount,
          groupAssignment: groupAssignment,
          knockoutSeeding: knockoutSeeding,
          onError: onError,
        );
      };
}

void _restoreRealCreateLeaguePageBuilder() {
  tournamentCreatePageBuilder =
      ({
        required List<GNEsportGroup> groups,
        required OnAddLeagueCallback onAddLeague,
      }) => CreateEsportLeaguePage(groups: groups, onAddLeague: onAddLeague);
}

class _SubmitLeaguePage extends StatefulWidget {
  final OnAddLeagueCallback onAddLeague;
  final TournamentMode mode;
  final String groupId;
  final List<String> participants;
  final int groupCount;
  final int advanceCount;
  final Map<String, int> groupAssignment;
  final List<String> knockoutSeeding;
  final void Function(Object error, StackTrace stackTrace)? onError;

  const _SubmitLeaguePage({
    required this.groupId,
    required this.onAddLeague,
    required this.mode,
    required this.participants,
    required this.groupCount,
    required this.advanceCount,
    required this.groupAssignment,
    required this.knockoutSeeding,
    this.onError,
  });

  @override
  State<_SubmitLeaguePage> createState() => _SubmitLeaguePageState();
}

class _SubmitLeaguePageState extends State<_SubmitLeaguePage> {
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _submit());
  }

  Future<void> _submit() async {
    if (_submitted) return;
    _submitted = true;
    try {
      final leagueId = await widget.onAddLeague(
        name: 'Test League',
        groupId: widget.groupId,
        startDate: null,
        endDate: null,
        description: '',
        rankPayoutEnabled: false,
        rankPayouts: const [],
        defaultMatchCost: 10,
        defaultPerGoalEnabled: false,
        defaultCostPerGoal: 0,
        mode: widget.mode,
        participants: widget.participants,
        groupCount: widget.groupCount,
        advanceCount: widget.advanceCount,
        knockoutSeeding: widget.knockoutSeeding,
        groupAssignment: widget.groupAssignment,
      );

      if (mounted) {
        Navigator.of(context).pop(leagueId);
      }
    } catch (error, stackTrace) {
      widget.onError?.call(error, stackTrace);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _CreateGenerationException implements Exception {
  final String message;

  const _CreateGenerationException(this.message);

  @override
  String toString() => '_CreateGenerationException: $message';
}

class _RollbackException implements Exception {
  final String message;

  const _RollbackException(this.message);

  @override
  String toString() => '_RollbackException: $message';
}

void _resetGetIt() {
  final getIt = GetIt.instance;
  if (getIt.isRegistered<EsportLeagueRepository>()) {
    getIt.unregister<EsportLeagueRepository>();
  }
  if (getIt.isRegistered<GNFirestore>()) {
    getIt.unregister<GNFirestore>();
  }
}

void main() {
  setUp(() {
    _restoreRealCreateLeaguePageBuilder();
  });

  setUpAll(() {
    registerFallbackValue(LoadMyLeagues());
    registerFallbackValue(LoadManagedLeagues());
    registerFallbackValue(LoadOtherLeagues());
    registerFallbackValue(LoadMoreMyLeagues());
    registerFallbackValue(LoadMoreManagedLeagues());
    registerFallbackValue(LoadMoreOtherLeagues());
    registerFallbackValue(RefreshTournaments());
    registerFallbackValue(TournamentMode.league);
  });

  tearDown(() {
    resetShowToast();
    _resetGetIt();
    _restoreRealCreateLeaguePageBuilder();
  });

  testWidgets('TournamentView renders empty state tabs', (tester) async {
    final tournamentBloc = _MockTournamentBloc();
    final groupBloc = _MockGroupBloc();
    final groupState = _groupState(userGroups: [_group('g1', 'Group One')]);
    when(() => tournamentBloc.state).thenReturn(
      const TournamentState(
        myStatus: ViewStatus.success,
        managedStatus: ViewStatus.success,
        otherStatus: ViewStatus.success,
      ),
    );
    when(() => groupBloc.state).thenReturn(groupState);

    await tester.pumpWidget(
      _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
    );

    expect(find.text('Tham gia'), findsOneWidget);
    expect(find.text('Quản lý'), findsOneWidget);
    expect(find.text('Khác'), findsOneWidget);
    expect(find.text('Không có giải đấu nào'), findsOneWidget);
  });

  testWidgets(
    'BlocConsumer listener shows toast when state has an error message',
    (tester) async {
      final tournamentBloc = _MockTournamentBloc();
      final groupBloc = _MockGroupBloc();
      const message = 'Unable to load leagues';
      String? toastMessage;
      setShowToastImpl((message, {gravity = ToastGravity.BOTTOM}) {
        toastMessage = message;
      });

      when(() => tournamentBloc.state).thenReturn(const TournamentState());
      whenListen(
        tournamentBloc,
        Stream.value(
          const TournamentState(
            myStatus: ViewStatus.success,
            managedStatus: ViewStatus.success,
            otherStatus: ViewStatus.success,
            errorMessage: message,
          ),
        ),
        initialState: const TournamentState(),
      );
      when(() => groupBloc.state).thenReturn(_groupState());

      await tester.pumpWidget(
        _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
      );

      expect(toastMessage, equals(message));
    },
  );

  testWidgets('Create button warns when user has no groups', (tester) async {
    final tournamentBloc = _MockTournamentBloc();
    final groupBloc = _MockGroupBloc();
    String? toastMessage;
    setShowToastImpl((message, {gravity = ToastGravity.BOTTOM}) {
      toastMessage = message;
    });

    when(() => tournamentBloc.state).thenReturn(
      const TournamentState(
        myStatus: ViewStatus.success,
        managedStatus: ViewStatus.success,
        otherStatus: ViewStatus.success,
      ),
    );
    when(() => groupBloc.state).thenReturn(_groupState());

    await tester.pumpWidget(
      _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
    );

    await tester.tap(find.text('Tạo giải đấu'));
    await tester.pump();

    expect(toastMessage, 'Bạn chưa tham gia nhóm nào. Hãy tham gia nhóm trước');
  });

  testWidgets('Create button opens create tournament page when group exists', (
    tester,
  ) async {
    final tournamentBloc = _MockTournamentBloc();
    final groupBloc = _MockGroupBloc();
    final leagueRepo = _MockLeagueRepository();
    final firestore = _MockFirestore();
    when(
      () => firestore.getUsersById(any<List<String>>()),
    ).thenAnswer((_) async => <String, GNUser>{});
    _registerCreateDependencies(leagueRepo: leagueRepo, firestore: firestore);

    when(() => tournamentBloc.state).thenReturn(
      const TournamentState(
        myStatus: ViewStatus.success,
        managedStatus: ViewStatus.success,
        otherStatus: ViewStatus.success,
      ),
    );
    when(
      () => groupBloc.state,
    ).thenReturn(_groupState(userGroups: [_group('g1', 'Nhóm Một')]));

    await tester.pumpWidget(
      _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
    );

    await tester.tap(find.text('Tạo giải đấu'));
    await tester.pumpAndSettle();

    expect(find.text('1/5'), findsOneWidget);
    expect(find.text('Nhóm Một'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump(const Duration(milliseconds: 20));
  });

  testWidgets(
    'Create callback creates league fixtures before toast and defers reload until detail pop',
    (tester) async {
      final tournamentBloc = _MockTournamentBloc();
      final groupBloc = _MockGroupBloc();
      final leagueRepo = _MockLeagueRepository();
      final firestore = _MockFirestore();
      final toastMessages = <String>[];
      final addLeagueCompleter = Completer<String>();
      final fixturesCompleter = Completer<void>();

      setShowToastImpl((message, {gravity = ToastGravity.BOTTOM}) {
        toastMessages.add(message);
      });
      when(
        () => firestore.getUsersById(any<List<String>>()),
      ).thenAnswer((_) async => <String, GNUser>{});
      _registerCreateDependencies(leagueRepo: leagueRepo, firestore: firestore);

      when(
        () => leagueRepo.addLeague(
          name: any(named: 'name'),
          groupId: any(named: 'groupId'),
          description: any(named: 'description'),
          rankPayoutEnabled: any(named: 'rankPayoutEnabled'),
          rankPayouts: any(named: 'rankPayouts'),
          defaultMatchCost: any(named: 'defaultMatchCost'),
          defaultPerGoalEnabled: any(named: 'defaultPerGoalEnabled'),
          defaultCostPerGoal: any(named: 'defaultCostPerGoal'),
          mode: any(named: 'mode'),
          groupCount: any(named: 'groupCount'),
          advanceCount: any(named: 'advanceCount'),
          participants: any(named: 'participants'),
          knockoutSeeding: any(named: 'knockoutSeeding'),
        ),
      ).thenAnswer((_) => addLeagueCompleter.future);
      when(
        () => leagueRepo.addMultipleParticipants(
          leagueId: any(named: 'leagueId'),
          userIds: any(named: 'userIds'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => leagueRepo.generateRound(
          leagueId: any(named: 'leagueId'),
          teamIds: any(named: 'teamIds'),
        ),
      ).thenAnswer((_) => fixturesCompleter.future);
      when(() => leagueRepo.deleteLeague(any())).thenAnswer((_) async {});

      when(() => tournamentBloc.state).thenReturn(
        const TournamentState(
          myStatus: ViewStatus.success,
          managedStatus: ViewStatus.success,
          otherStatus: ViewStatus.success,
        ),
      );
      when(
        () => groupBloc.state,
      ).thenReturn(_groupState(userGroups: [_group('g1', 'Nhóm Một')]));

      _setCreateLeaguePageBuilder(mode: TournamentMode.league);

      await tester.pumpWidget(
        _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
      );

      await tester.tap(find.text('Tạo giải đấu'));
      await tester.pumpAndSettle();

      expect(toastMessages, isEmpty);
      verify(
        () => leagueRepo.addLeague(
          name: 'Test League',
          groupId: 'g1',
          description: '',
          rankPayoutEnabled: false,
          rankPayouts: const [],
          defaultMatchCost: 10,
          defaultPerGoalEnabled: false,
          defaultCostPerGoal: 0,
          mode: TournamentMode.league,
          groupCount: 2,
          advanceCount: 2,
          participants: const ['u1', 'u2'],
          knockoutSeeding: const ['A1', 'A2'],
        ),
      ).called(1);

      addLeagueCompleter.complete('league-league');
      await tester.pump();

      expect(toastMessages, isEmpty);
      verify(
        () => leagueRepo.generateRound(
          leagueId: 'league-league',
          teamIds: const ['u1', 'u2'],
        ),
      ).called(1);

      fixturesCompleter.complete();
      await tester.pumpAndSettle();

      expect(find.text('tournament league-league'), findsOneWidget);
      expect(toastMessages, hasLength(1));

      verifyNever(() => tournamentBloc.add(any(that: isA<LoadMyLeagues>())));
      verifyNever(
        () => tournamentBloc.add(any(that: isA<LoadManagedLeagues>())),
      );

      await tester.pageBack();
      await tester.pumpAndSettle();

      verifyNever(
        () => leagueRepo.addMultipleParticipants(
          leagueId: any(named: 'leagueId'),
          userIds: any(named: 'userIds'),
        ),
      );
      verifyNever(
        () => leagueRepo.generateCupBracket(
          leagueId: any(named: 'leagueId'),
          seededTeamIds: any(named: 'seededTeamIds'),
        ),
      );
      verifyNever(
        () => leagueRepo.generateFullTournament(
          leagueId: any(named: 'leagueId'),
          groups: any(named: 'groups'),
          advanceCount: any(named: 'advanceCount'),
          knockoutSeeding: any(named: 'knockoutSeeding'),
        ),
      );
      verifyNever(() => leagueRepo.deleteLeague(any()));
      verify(
        () => tournamentBloc.add(any(that: isA<LoadMyLeagues>())),
      ).called(1);
      verify(
        () => tournamentBloc.add(any(that: isA<LoadManagedLeagues>())),
      ).called(1);
      expect(toastMessages, hasLength(1));
    },
  );

  testWidgets('Create callback handles cup mode and creates cup bracket', (
    tester,
  ) async {
    final tournamentBloc = _MockTournamentBloc();
    final groupBloc = _MockGroupBloc();
    final leagueRepo = _MockLeagueRepository();
    final firestore = _MockFirestore();

    when(
      () => firestore.getUsersById(any<List<String>>()),
    ).thenAnswer((_) async => <String, GNUser>{});
    _registerCreateDependencies(leagueRepo: leagueRepo, firestore: firestore);

    when(
      () => leagueRepo.addLeague(
        name: any(named: 'name'),
        groupId: any(named: 'groupId'),
        description: any(named: 'description'),
        rankPayoutEnabled: any(named: 'rankPayoutEnabled'),
        rankPayouts: any(named: 'rankPayouts'),
        defaultMatchCost: any(named: 'defaultMatchCost'),
        defaultPerGoalEnabled: any(named: 'defaultPerGoalEnabled'),
        defaultCostPerGoal: any(named: 'defaultCostPerGoal'),
        mode: any(named: 'mode'),
        groupCount: any(named: 'groupCount'),
        advanceCount: any(named: 'advanceCount'),
        participants: any(named: 'participants'),
        knockoutSeeding: any(named: 'knockoutSeeding'),
      ),
    ).thenAnswer((_) async => 'league-cup');
    when(
      () => leagueRepo.addMultipleParticipants(
        leagueId: any(named: 'leagueId'),
        userIds: any(named: 'userIds'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => leagueRepo.generateCupBracket(
        leagueId: any(named: 'leagueId'),
        seededTeamIds: any(named: 'seededTeamIds'),
      ),
    ).thenAnswer((_) async {});
    when(() => leagueRepo.deleteLeague(any())).thenAnswer((_) async {});

    when(() => tournamentBloc.state).thenReturn(
      const TournamentState(
        myStatus: ViewStatus.success,
        managedStatus: ViewStatus.success,
        otherStatus: ViewStatus.success,
      ),
    );
    when(
      () => groupBloc.state,
    ).thenReturn(_groupState(userGroups: [_group('g1', 'Nhóm Một')]));

    _setCreateLeaguePageBuilder(
      mode: TournamentMode.cup,
      participants: const ['u1', 'u2', 'u3', 'u4'],
      knockoutSeeding: const ['u1', 'u2', 'u3', 'u4'],
    );

    await tester.pumpWidget(
      _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
    );
    await tester.tap(find.text('Tạo giải đấu'));
    await tester.pumpAndSettle();

    expect(find.text('tournament league-cup'), findsOneWidget);
    verifyNever(() => tournamentBloc.add(any(that: isA<LoadMyLeagues>())));
    verifyNever(
      () => tournamentBloc.add(any(that: isA<LoadManagedLeagues>())),
    );

    await tester.pageBack();
    await tester.pumpAndSettle();

    verify(
      () => leagueRepo.addLeague(
        name: 'Test League',
        groupId: 'g1',
        description: '',
        rankPayoutEnabled: false,
        rankPayouts: const [],
        defaultMatchCost: 10,
        defaultPerGoalEnabled: false,
        defaultCostPerGoal: 0,
        mode: TournamentMode.cup,
        groupCount: 2,
        advanceCount: 2,
        participants: const ['u1', 'u2', 'u3', 'u4'],
        knockoutSeeding: const ['u1', 'u2', 'u3', 'u4'],
      ),
    ).called(1);
    verifyNever(
      () => leagueRepo.addMultipleParticipants(
        leagueId: any(named: 'leagueId'),
        userIds: any(named: 'userIds'),
      ),
    );
    verify(
      () => leagueRepo.generateCupBracket(
        leagueId: 'league-cup',
        seededTeamIds: const ['u1', 'u2', 'u3', 'u4'],
      ),
    ).called(1);
    verifyNever(
      () => leagueRepo.generateRound(
        leagueId: any(named: 'leagueId'),
        teamIds: any(named: 'teamIds'),
      ),
    );
    verifyNever(
      () => leagueRepo.generateFullTournament(
        leagueId: any(named: 'leagueId'),
        groups: any(named: 'groups'),
        advanceCount: any(named: 'advanceCount'),
        knockoutSeeding: any(named: 'knockoutSeeding'),
      ),
    );
    verify(
      () => tournamentBloc.add(any(that: isA<LoadMyLeagues>())),
    ).called(1);
    verify(
      () => tournamentBloc.add(any(that: isA<LoadManagedLeagues>())),
    ).called(1);
  });

  testWidgets(
    'Create callback handles full mode and creates full tournament groups',
    (tester) async {
      final tournamentBloc = _MockTournamentBloc();
      final groupBloc = _MockGroupBloc();
      final leagueRepo = _MockLeagueRepository();
      final firestore = _MockFirestore();

      when(
        () => firestore.getUsersById(any<List<String>>()),
      ).thenAnswer((_) async => <String, GNUser>{});
      _registerCreateDependencies(leagueRepo: leagueRepo, firestore: firestore);

      when(
        () => leagueRepo.addLeague(
          name: any(named: 'name'),
          groupId: any(named: 'groupId'),
          description: any(named: 'description'),
          rankPayoutEnabled: any(named: 'rankPayoutEnabled'),
          rankPayouts: any(named: 'rankPayouts'),
          defaultMatchCost: any(named: 'defaultMatchCost'),
          defaultPerGoalEnabled: any(named: 'defaultPerGoalEnabled'),
          defaultCostPerGoal: any(named: 'defaultCostPerGoal'),
          mode: any(named: 'mode'),
          groupCount: any(named: 'groupCount'),
          advanceCount: any(named: 'advanceCount'),
          participants: any(named: 'participants'),
          knockoutSeeding: any(named: 'knockoutSeeding'),
        ),
      ).thenAnswer((_) async => 'league-full');
      when(
        () => leagueRepo.addMultipleParticipants(
          leagueId: any(named: 'leagueId'),
          userIds: any(named: 'userIds'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => leagueRepo.generateFullTournament(
          leagueId: any(named: 'leagueId'),
          groups: any(named: 'groups'),
          advanceCount: any(named: 'advanceCount'),
          knockoutSeeding: any(named: 'knockoutSeeding'),
        ),
      ).thenAnswer((_) async {});
      when(() => leagueRepo.deleteLeague(any())).thenAnswer((_) async {});

      when(() => tournamentBloc.state).thenReturn(
        const TournamentState(
          myStatus: ViewStatus.success,
          managedStatus: ViewStatus.success,
          otherStatus: ViewStatus.success,
        ),
      );
      when(
        () => groupBloc.state,
      ).thenReturn(_groupState(userGroups: [_group('g1', 'Nhóm Một')]));

      _setCreateLeaguePageBuilder(
        mode: TournamentMode.full,
        participants: const ['u1', 'u2', 'u3', 'u4'],
        groupCount: 2,
        advanceCount: 2,
        knockoutSeeding: const ['A1', 'A2', 'A3', 'A4'],
        groupAssignment: const {'u1': 0, 'u2': 1, 'u3': 0, 'u4': 1},
      );

      await tester.pumpWidget(
        _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
      );
      await tester.tap(find.text('Tạo giải đấu'));
      await tester.pumpAndSettle();

      expect(find.text('tournament league-full'), findsOneWidget);
      verifyNever(() => tournamentBloc.add(any(that: isA<LoadMyLeagues>())));
      verifyNever(
        () => tournamentBloc.add(any(that: isA<LoadManagedLeagues>())),
      );

      await tester.pageBack();
      await tester.pumpAndSettle();

      verify(
        () => leagueRepo.addLeague(
          name: 'Test League',
          groupId: 'g1',
          description: '',
          rankPayoutEnabled: false,
          rankPayouts: const [],
          defaultMatchCost: 10,
          defaultPerGoalEnabled: false,
          defaultCostPerGoal: 0,
          mode: TournamentMode.full,
          groupCount: 2,
          advanceCount: 2,
          participants: const ['u1', 'u2', 'u3', 'u4'],
          knockoutSeeding: const ['A1', 'A2', 'A3', 'A4'],
        ),
      ).called(1);
      verifyNever(
        () => leagueRepo.addMultipleParticipants(
          leagueId: any(named: 'leagueId'),
          userIds: any(named: 'userIds'),
        ),
      );
      verify(
        () => leagueRepo.generateFullTournament(
          leagueId: 'league-full',
          groups: const [
            ['u1', 'u3'],
            ['u2', 'u4'],
          ],
          advanceCount: 2,
          knockoutSeeding: const ['A1', 'A2', 'A3', 'A4'],
        ),
      ).called(1);
      verifyNever(
        () => leagueRepo.generateRound(
          leagueId: any(named: 'leagueId'),
          teamIds: any(named: 'teamIds'),
        ),
      );
      verifyNever(
        () => leagueRepo.generateCupBracket(
          leagueId: any(named: 'leagueId'),
          seededTeamIds: any(named: 'seededTeamIds'),
        ),
      );
      verify(
        () => tournamentBloc.add(any(that: isA<LoadMyLeagues>())),
      ).called(1);
      verify(
        () => tournamentBloc.add(any(that: isA<LoadManagedLeagues>())),
      ).called(1);
    },
  );

  testWidgets('Create callback rolls back league when generation throws', (
    tester,
  ) async {
    final tournamentBloc = _MockTournamentBloc();
    final groupBloc = _MockGroupBloc();
    final leagueRepo = _MockLeagueRepository();
    final firestore = _MockFirestore();
    const createError = _CreateGenerationException('fixture generation failed');
    final createStack = StackTrace.fromString('create-generation-stack');
    Object? observedError;
    StackTrace? observedStack;
    final toastMessages = <String>[];

    setShowToastImpl((message, {gravity = ToastGravity.BOTTOM}) {
      toastMessages.add(message);
    });

    when(
      () => firestore.getUsersById(any<List<String>>()),
    ).thenAnswer((_) async => <String, GNUser>{});
    _registerCreateDependencies(leagueRepo: leagueRepo, firestore: firestore);

    when(
      () => leagueRepo.addLeague(
        name: any(named: 'name'),
        groupId: any(named: 'groupId'),
        description: any(named: 'description'),
        rankPayoutEnabled: any(named: 'rankPayoutEnabled'),
        rankPayouts: any(named: 'rankPayouts'),
        defaultMatchCost: any(named: 'defaultMatchCost'),
        defaultPerGoalEnabled: any(named: 'defaultPerGoalEnabled'),
        defaultCostPerGoal: any(named: 'defaultCostPerGoal'),
        mode: any(named: 'mode'),
        groupCount: any(named: 'groupCount'),
        advanceCount: any(named: 'advanceCount'),
        participants: any(named: 'participants'),
        knockoutSeeding: any(named: 'knockoutSeeding'),
      ),
    ).thenAnswer((_) async => 'league-fail');
    when(
      () => leagueRepo.addMultipleParticipants(
        leagueId: any(named: 'leagueId'),
        userIds: any(named: 'userIds'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => leagueRepo.generateRound(
        leagueId: any(named: 'leagueId'),
        teamIds: any(named: 'teamIds'),
      ),
    ).thenAnswer((_) => Future<void>.error(createError, createStack));
    when(() => leagueRepo.deleteLeague(any())).thenAnswer((_) async {});

    when(() => tournamentBloc.state).thenReturn(
      const TournamentState(
        myStatus: ViewStatus.success,
        managedStatus: ViewStatus.success,
        otherStatus: ViewStatus.success,
      ),
    );
    when(
      () => groupBloc.state,
    ).thenReturn(_groupState(userGroups: [_group('g1', 'Nhóm Một')]));

    _setCreateLeaguePageBuilder(
      mode: TournamentMode.league,
      onError: (error, stackTrace) {
        observedError = error;
        observedStack = stackTrace;
      },
    );

    await tester.pumpWidget(
      _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
    );
    await tester.tap(find.text('Tạo giải đấu'));
    await tester.pumpAndSettle();

    verify(() => leagueRepo.deleteLeague('league-fail')).called(1);
    expect(observedError, same(createError));
    expect(observedError, isA<_CreateGenerationException>());
    expect(observedError.toString(), contains('fixture generation failed'));
    expect(observedStack.toString(), contains('create-generation-stack'));
    expect(find.text('tournament league-fail'), findsNothing);
    verifyNever(() => tournamentBloc.add(any(that: isA<LoadMyLeagues>())));
    verifyNever(() => tournamentBloc.add(any(that: isA<LoadManagedLeagues>())));
    expect(toastMessages, isEmpty);
  });

  testWidgets(
    'Create callback preserves generation error when rollback also throws',
    (tester) async {
      final tournamentBloc = _MockTournamentBloc();
      final groupBloc = _MockGroupBloc();
      final leagueRepo = _MockLeagueRepository();
      final firestore = _MockFirestore();
      const createError = _CreateGenerationException(
        'original fixture generation failure',
      );
      const rollbackError = _RollbackException('delete failed');
      final createStack = StackTrace.fromString('original-create-stack');
      Object? observedError;
      StackTrace? observedStack;
      final toastMessages = <String>[];
      final debugMessages = <String>[];
      final previousDebugPrint = debugPrint;
      debugPrint = (message, {wrapWidth}) {
        if (message != null) debugMessages.add(message);
      };
      addTearDown(() => debugPrint = previousDebugPrint);

      setShowToastImpl((message, {gravity = ToastGravity.BOTTOM}) {
        toastMessages.add(message);
      });
      when(
        () => firestore.getUsersById(any<List<String>>()),
      ).thenAnswer((_) async => <String, GNUser>{});
      _registerCreateDependencies(leagueRepo: leagueRepo, firestore: firestore);

      when(
        () => leagueRepo.addLeague(
          name: any(named: 'name'),
          groupId: any(named: 'groupId'),
          description: any(named: 'description'),
          rankPayoutEnabled: any(named: 'rankPayoutEnabled'),
          rankPayouts: any(named: 'rankPayouts'),
          defaultMatchCost: any(named: 'defaultMatchCost'),
          defaultPerGoalEnabled: any(named: 'defaultPerGoalEnabled'),
          defaultCostPerGoal: any(named: 'defaultCostPerGoal'),
          mode: any(named: 'mode'),
          groupCount: any(named: 'groupCount'),
          advanceCount: any(named: 'advanceCount'),
          participants: any(named: 'participants'),
          knockoutSeeding: any(named: 'knockoutSeeding'),
        ),
      ).thenAnswer((_) async => 'league-rollback-fail');
      when(
        () => leagueRepo.addMultipleParticipants(
          leagueId: any(named: 'leagueId'),
          userIds: any(named: 'userIds'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => leagueRepo.generateRound(
          leagueId: any(named: 'leagueId'),
          teamIds: any(named: 'teamIds'),
        ),
      ).thenAnswer((_) => Future<void>.error(createError, createStack));
      when(
        () => leagueRepo.deleteLeague('league-rollback-fail'),
      ).thenThrow(rollbackError);

      when(() => tournamentBloc.state).thenReturn(
        const TournamentState(
          myStatus: ViewStatus.success,
          managedStatus: ViewStatus.success,
          otherStatus: ViewStatus.success,
        ),
      );
      when(
        () => groupBloc.state,
      ).thenReturn(_groupState(userGroups: [_group('g1', 'Nhóm Một')]));

      _setCreateLeaguePageBuilder(
        mode: TournamentMode.league,
        onError: (error, stackTrace) {
          observedError = error;
          observedStack = stackTrace;
        },
      );

      try {
        await tester.pumpWidget(
          _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
        );
        await tester.tap(find.text('Tạo giải đấu'));
        await tester.pumpAndSettle();
      } finally {
        debugPrint = previousDebugPrint;
      }

      verify(() => leagueRepo.deleteLeague('league-rollback-fail')).called(1);
      expect(observedError, same(createError));
      expect(observedError, isA<_CreateGenerationException>());
      expect(
        observedError.toString(),
        contains('original fixture generation failure'),
      );
      expect(observedStack.toString(), contains('original-create-stack'));
      expect(
        debugMessages.join('\n'),
        allOf(
          contains('League create rollback failed'),
          contains(rollbackError.toString()),
        ),
      );
      expect(find.text('tournament league-rollback-fail'), findsNothing);
      verifyNever(() => tournamentBloc.add(any(that: isA<LoadMyLeagues>())));
      verifyNever(
        () => tournamentBloc.add(any(that: isA<LoadManagedLeagues>())),
      );
      expect(toastMessages, isEmpty);
    },
  );

  testWidgets(
    'Hero stat shows my count plus-sign, live count and players count',
    (tester) async {
      final tournamentBloc = _MockTournamentBloc();
      final groupBloc = _MockGroupBloc();

      when(() => tournamentBloc.state).thenReturn(
        TournamentState(
          myStatus: ViewStatus.success,
          managedStatus: ViewStatus.success,
          otherStatus: ViewStatus.success,
          myHasMore: true,
          myLeagues: [
            _league(
              'l1',
              'Premier',
              status: GNEsportLeagueStatus.ongoing.value,
              participants: const ['u1', 'u2'],
            ),
            _league(
              'l2',
              'Friendly',
              status: GNEsportLeagueStatus.finished.value,
              participants: const ['u2', 'u3'],
            ),
          ],
          otherLeagues: [
            _league(
              'l3',
              'World Cup',
              status: GNEsportLeagueStatus.ongoing.value,
              participants: const ['u3', 'u4'],
            ),
          ],
        ),
      );
      when(() => groupBloc.state).thenReturn(_groupState());

      await tester.pumpWidget(
        _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
      );

      // My leagues = 2; hasMore = true => "2+"
      expect(find.text('2+'), findsOneWidget);
      // 2 leagues are ongoing (my + other) and 4 unique participants.
      expect(find.text('2'), findsAtLeastNWidgets(1));
      expect(find.text('4'), findsAtLeastNWidgets(1));
    },
  );

  testWidgets('Tab switching shows My, Managed, Other list contents', (
    tester,
  ) async {
    final tournamentBloc = _MockTournamentBloc();
    final groupBloc = _MockGroupBloc();
    when(() => tournamentBloc.state).thenReturn(
      TournamentState(
        myStatus: ViewStatus.success,
        managedStatus: ViewStatus.success,
        otherStatus: ViewStatus.success,
        myLeagues: [_league('l1', 'Tham gia 1')],
        managedLeagues: [_league('l2', 'Quản lý 1')],
        otherLeagues: [_league('l3', 'Khác 1')],
      ),
    );
    when(() => groupBloc.state).thenReturn(_groupState());

    await tester.pumpWidget(
      _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
    );
    expect(find.text('Tham gia 1'), findsOneWidget);

    await tester.tap(find.text('Quản lý'));
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pumpAndSettle();
    expect(find.text('Tham gia 1'), findsNothing);
    expect(find.text('Quản lý 1'), findsOneWidget);

    await tester.tap(find.text('Khác'));
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pumpAndSettle();
    expect(find.text('Quản lý 1'), findsNothing);
    expect(find.text('Khác 1'), findsOneWidget);
  });

  testWidgets('Tab switching returns to joined tab', (tester) async {
    final tournamentBloc = _MockTournamentBloc();
    final groupBloc = _MockGroupBloc();
    when(() => tournamentBloc.state).thenReturn(
      TournamentState(
        myStatus: ViewStatus.success,
        managedStatus: ViewStatus.success,
        otherStatus: ViewStatus.success,
        myLeagues: [_league('l1', 'Tham gia quay lại')],
        managedLeagues: [_league('m1', 'Quản lý quay lại')],
        otherLeagues: [_league('o1', 'Khác quay lại')],
      ),
    );
    when(() => groupBloc.state).thenReturn(_groupState());

    await tester.pumpWidget(
      _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
    );

    await tester.tap(find.text('Quản lý'));
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pumpAndSettle();
    expect(find.text('Quản lý quay lại'), findsOneWidget);

    await tester.tap(find.text('Khác'));
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pumpAndSettle();
    expect(find.text('Khác quay lại'), findsOneWidget);

    await tester.tap(find.text('Tham gia'));
    await tester.pumpAndSettle();
    expect(find.text('Tham gia quay lại'), findsOneWidget);
  });

  testWidgets('Loading and empty states appear in each tab branch', (
    tester,
  ) async {
    final tournamentBloc = _MockTournamentBloc();
    final groupBloc = _MockGroupBloc();
    when(() => tournamentBloc.state).thenReturn(
      const TournamentState(
        myStatus: ViewStatus.loading,
        managedStatus: ViewStatus.loading,
        otherStatus: ViewStatus.success,
      ),
    );
    when(() => groupBloc.state).thenReturn(_groupState());

    await tester.pumpWidget(
      _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
    );
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('Không có giải đấu nào'), findsNothing);

    await tester.tap(find.text('Quản lý'));
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('Tạo giải đấu mới để bắt đầu quản lý'), findsNothing);

    expect(find.text('Không có giải đấu nào'), findsNothing);
  });

  testWidgets('My tab shows list end marker when hasMore is false', (
    tester,
  ) async {
    final tournamentBloc = _MockTournamentBloc();
    final groupBloc = _MockGroupBloc();

    when(() => tournamentBloc.state).thenReturn(
      TournamentState(
        myStatus: ViewStatus.success,
        managedStatus: ViewStatus.success,
        otherStatus: ViewStatus.success,
        myHasMore: false,
        myLeagues: [_league('l1', 'Premier Cup')],
      ),
    );
    when(() => groupBloc.state).thenReturn(_groupState());

    await tester.pumpWidget(
      _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
    );

    expect(find.text('Premier Cup'), findsOneWidget);
    expect(find.text('Đã hết'), findsOneWidget);
  });

  testWidgets('My tab dispatches load-more when scrolled near the end', (
    tester,
  ) async {
    final tournamentBloc = _MockTournamentBloc();
    final groupBloc = _MockGroupBloc();

    when(() => tournamentBloc.state).thenReturn(
      TournamentState(
        myStatus: ViewStatus.success,
        managedStatus: ViewStatus.success,
        otherStatus: ViewStatus.success,
        myHasMore: true,
        myLeagues: List.generate(
          15,
          (index) => _league('l$index', 'League $index', participants: []),
        ),
      ),
    );
    when(() => groupBloc.state).thenReturn(_groupState());

    await tester.pumpWidget(
      _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
    );

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pump(const Duration(milliseconds: 20));

    verify(
      () => tournamentBloc.add(any(that: isA<LoadMoreMyLeagues>())),
    ).called(1);
  });

  testWidgets('Managed tab dispatches load-more', (tester) async {
    final tournamentBloc = _MockTournamentBloc();
    final groupBloc = _MockGroupBloc();

    when(() => tournamentBloc.state).thenReturn(
      TournamentState(
        myStatus: ViewStatus.success,
        managedStatus: ViewStatus.success,
        otherStatus: ViewStatus.success,
        managedHasMore: true,
        managedLeagues: List.generate(
          15,
          (index) => _league('m$index', 'Managed $index', participants: []),
        ),
      ),
    );
    when(() => groupBloc.state).thenReturn(_groupState());

    await tester.pumpWidget(
      _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
    );
    await tester.tap(find.text('Quản lý'));
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pump(const Duration(milliseconds: 20));

    verify(
      () => tournamentBloc.add(any(that: isA<LoadMoreManagedLeagues>())),
    ).called(1);
  });

  testWidgets('Other tab dispatches load-more when scrolled near the end', (
    tester,
  ) async {
    final tournamentBloc = _MockTournamentBloc();
    final groupBloc = _MockGroupBloc();

    when(() => tournamentBloc.state).thenReturn(
      TournamentState(
        myStatus: ViewStatus.success,
        managedStatus: ViewStatus.success,
        otherStatus: ViewStatus.success,
        otherLeagues: List.generate(
          15,
          (index) => _league('o$index', 'Other $index', participants: []),
        ),
        otherHasMore: true,
      ),
    );
    when(() => groupBloc.state).thenReturn(_groupState());

    await tester.pumpWidget(
      _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
    );
    await tester.tap(find.text('Khác'));
    await tester.pumpAndSettle();

    final list = find
        .ancestor(of: find.text('Other 0'), matching: find.byType(ListView))
        .first;
    await tester.drag(list, const Offset(0, -3000));
    await tester.pump(const Duration(milliseconds: 20));

    verify(
      () => tournamentBloc.add(any(that: isA<LoadMoreOtherLeagues>())),
    ).called(1);
  });

  testWidgets('Managed tab shows end marker when hasMore is false', (
    tester,
  ) async {
    final tournamentBloc = _MockTournamentBloc();
    final groupBloc = _MockGroupBloc();

    when(() => tournamentBloc.state).thenReturn(
      TournamentState(
        myStatus: ViewStatus.success,
        managedStatus: ViewStatus.success,
        otherStatus: ViewStatus.success,
        managedHasMore: false,
        managedLeagues: [_league('m1', 'Managed done')],
      ),
    );
    when(() => groupBloc.state).thenReturn(_groupState());

    await tester.pumpWidget(
      _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
    );
    await tester.tap(find.text('Quản lý'));
    await tester.pumpAndSettle();

    expect(find.text('Managed done'), findsOneWidget);
    expect(find.text('Đã hết'), findsOneWidget);
  });

  testWidgets('Other tab opens detail and shows end marker', (tester) async {
    final tournamentBloc = _MockTournamentBloc();
    final groupBloc = _MockGroupBloc();

    when(() => tournamentBloc.state).thenReturn(
      TournamentState(
        myStatus: ViewStatus.success,
        managedStatus: ViewStatus.success,
        otherStatus: ViewStatus.success,
        otherHasMore: false,
        otherLeagues: [_league('o1', 'Other done')],
      ),
    );
    when(() => groupBloc.state).thenReturn(_groupState());

    await tester.pumpWidget(
      _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
    );
    await tester.tap(find.text('Khác'));
    await tester.pumpAndSettle();

    expect(find.text('Other done'), findsOneWidget);
    expect(find.text('Đã hết'), findsOneWidget);

    await tester.tap(find.text('Other done'));
    await tester.pumpAndSettle();
    expect(find.text('tournament o1'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
  });

  testWidgets('RefreshIndicator callback dispatches RefreshTournaments', (
    tester,
  ) async {
    final tournamentBloc = _MockTournamentBloc();
    final groupBloc = _MockGroupBloc();
    final controller = StreamController<TournamentState>();
    final initial = TournamentState(
      myStatus: ViewStatus.success,
      managedStatus: ViewStatus.success,
      otherStatus: ViewStatus.success,
    );
    when(() => tournamentBloc.state).thenReturn(initial);
    whenListen(tournamentBloc, controller.stream, initialState: initial);
    when(() => groupBloc.state).thenReturn(_groupState());

    await tester.pumpWidget(
      _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
    );

    final refresh = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator).first,
    );
    final refreshFuture = refresh.onRefresh();
    controller.add(initial.copyWith(refreshTick: 1));
    await refreshFuture;
    await controller.close();

    verify(() => tournamentBloc.add(RefreshTournaments())).called(1);
  });

  testWidgets('Managed RefreshIndicator dispatches RefreshTournaments', (
    tester,
  ) async {
    final tournamentBloc = _MockTournamentBloc();
    final groupBloc = _MockGroupBloc();
    final controller = StreamController<TournamentState>();
    final initial = TournamentState(
      myStatus: ViewStatus.success,
      managedStatus: ViewStatus.success,
      otherStatus: ViewStatus.success,
      managedLeagues: [_league('m1', 'Managed Refresh')],
    );
    when(() => tournamentBloc.state).thenReturn(initial);
    whenListen(tournamentBloc, controller.stream, initialState: initial);
    when(() => groupBloc.state).thenReturn(_groupState());

    await tester.pumpWidget(
      _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
    );

    await tester.tap(find.text('Quản lý'));
    await tester.pumpAndSettle();

    final refresh = tester.widget<RefreshIndicator>(
      find
          .ancestor(
            of: find.text('Managed Refresh'),
            matching: find.byType(RefreshIndicator),
          )
          .first,
    );
    final refreshFuture = refresh.onRefresh();
    controller.add(initial.copyWith(refreshTick: 1));
    await refreshFuture;
    await controller.close();

    verify(() => tournamentBloc.add(RefreshTournaments())).called(1);
  });

  testWidgets('Other RefreshIndicator dispatches RefreshTournaments', (
    tester,
  ) async {
    final tournamentBloc = _MockTournamentBloc();
    final groupBloc = _MockGroupBloc();
    final controller = StreamController<TournamentState>();
    final initial = TournamentState(
      myStatus: ViewStatus.success,
      managedStatus: ViewStatus.success,
      otherStatus: ViewStatus.success,
      otherLeagues: [_league('o1', 'Other Refresh')],
    );
    when(() => tournamentBloc.state).thenReturn(initial);
    whenListen(tournamentBloc, controller.stream, initialState: initial);
    when(() => groupBloc.state).thenReturn(_groupState());

    await tester.pumpWidget(
      _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
    );

    await tester.tap(find.text('Khác'));
    await tester.pumpAndSettle();

    final refresh = tester.widget<RefreshIndicator>(
      find
          .ancestor(
            of: find.text('Other Refresh'),
            matching: find.byType(RefreshIndicator),
          )
          .first,
    );
    final refreshFuture = refresh.onRefresh();
    controller.add(initial.copyWith(refreshTick: 1));
    await refreshFuture;
    await controller.close();

    verify(() => tournamentBloc.add(RefreshTournaments())).called(1);
  });

  testWidgets(
    'Managed list item opens detail and reloads managed tab on return',
    (tester) async {
      final tournamentBloc = _MockTournamentBloc();
      final groupBloc = _MockGroupBloc();

      when(() => tournamentBloc.state).thenReturn(
        TournamentState(
          myStatus: ViewStatus.success,
          managedStatus: ViewStatus.success,
          otherStatus: ViewStatus.success,
          managedLeagues: [_league('l2', 'Giải đấu quản lý')],
        ),
      );
      when(() => groupBloc.state).thenReturn(_groupState());

      await tester.pumpWidget(
        _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
      );

      await tester.tap(find.text('Quản lý'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giải đấu quản lý'));
      await tester.pumpAndSettle();
      expect(find.text('tournament l2'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      verify(
        () => tournamentBloc.add(any(that: isA<LoadManagedLeagues>())),
      ).called(1);
    },
  );

  testWidgets('My list item opens detail and reloads my tab on return', (
    tester,
  ) async {
    final tournamentBloc = _MockTournamentBloc();
    final groupBloc = _MockGroupBloc();

    when(() => tournamentBloc.state).thenReturn(
      TournamentState(
        myStatus: ViewStatus.success,
        managedStatus: ViewStatus.success,
        otherStatus: ViewStatus.success,
        myLeagues: [_league('l1', 'Giải đấu của tôi')],
      ),
    );
    when(() => groupBloc.state).thenReturn(_groupState());

    await tester.pumpWidget(
      _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
    );

    await tester.tap(find.text('Giải đấu của tôi'));
    await tester.pumpAndSettle();
    expect(find.text('tournament l1'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    verify(() => tournamentBloc.add(any(that: isA<LoadMyLeagues>()))).called(1);
  });

  testWidgets('TournamentItem renders fallback title and single date format', (
    tester,
  ) async {
    final tournamentBloc = _MockTournamentBloc();
    final groupBloc = _MockGroupBloc();
    final group = _group('g1', 'Group One');
    final groupState = _groupState(userGroups: [group]);
    when(() => tournamentBloc.state).thenReturn(
      TournamentState(
        myStatus: ViewStatus.success,
        managedStatus: ViewStatus.success,
        otherStatus: ViewStatus.success,
        myLeagues: [_league('l1', '', hasEndDate: false, group: group)],
        myHasMore: false,
      ),
    );
    when(() => groupBloc.state).thenReturn(groupState);

    await tester.pumpWidget(
      _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
    );

    expect(find.text('Group One - 01/01/2026'), findsOneWidget);
    expect(find.text('01/01/2026'), findsOneWidget);
  });

  testWidgets('TournamentItem renders explicit title and date range format', (
    tester,
  ) async {
    final tournamentBloc = _MockTournamentBloc();
    final groupBloc = _MockGroupBloc();
    final group = _group('g1', 'Group One');
    when(() => tournamentBloc.state).thenReturn(
      TournamentState(
        myStatus: ViewStatus.success,
        managedStatus: ViewStatus.success,
        otherStatus: ViewStatus.success,
        myLeagues: [
          _league(
            'l1',
            'League Title',
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 1, 15),
            group: group,
          ),
        ],
        myHasMore: false,
      ),
    );
    when(() => groupBloc.state).thenReturn(_groupState(userGroups: [group]));

    await tester.pumpWidget(
      _wrap(tournamentBloc: tournamentBloc, groupBloc: groupBloc),
    );

    expect(find.text('League Title'), findsOneWidget);
    expect(find.text('01/01 - 15/01/2026'), findsOneWidget);
  });
}
