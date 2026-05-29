import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/firebase/remote_config/gn_remote_config.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/tournament_detail_view.dart';

class _MockBloc extends MockBloc<TournamentDetailEvent, TournamentDetailState>
    implements TournamentDetailBloc {}

class _MockRemoteConfig extends Mock implements GNRemoteConfig {}

class _DetailState extends TournamentDetailState {
  final bool member;
  final bool admin;

  const _DetailState({
    super.viewStatus,
    super.league,
    super.participants,
    super.matches,
    super.users,
    this.member = false,
    this.admin = false,
  });

  @override
  bool get currentUserIsMember => member;

  @override
  bool get currentUserIsLeagueAdmin => admin;
}

GNUser _user(String id, String name) {
  return GNUser(
    id: id,
    displayName: name,
    phoneNumber: null,
    email: '$id@example.com',
    photoUrl: null,
    role: 'user',
    fcmToken: '',
  );
}

GNEsportGroup _group() {
  return GNEsportGroup(
    id: 'g1',
    groupName: 'Group One',
    ownerId: 'owner',
    members: const ['owner', 'u1', 'u2'],
    description: '',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    status: 'active',
  );
}

GNEsportLeague _league({
  String name = 'League One',
  TournamentMode mode = TournamentMode.league,
  String status = 'ongoing',
  bool rankPayoutEnabled = false,
  List<int> rankPayouts = const [],
}) {
  return GNEsportLeague(
    id: 'l1',
    ownerId: 'owner',
    groupId: 'g1',
    name: name,
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 1, 31),
    isActive: true,
    description: '',
    participants: const ['u1', 'u2'],
    status: status,
    group: _group(),
    mode: mode,
    rankPayoutEnabled: rankPayoutEnabled,
    rankPayouts: rankPayouts,
  );
}

GNEsportLeagueStat _stat(String userId, String name, int wins) {
  return GNEsportLeagueStat(
    id: 's_$userId',
    userId: userId,
    leagueId: 'l1',
    matchesPlayed: 1,
    goals: wins + 1,
    goalsConceded: 0,
    wins: wins,
    draws: 0,
    losses: 0,
    user: _user(userId, name),
  );
}

GNEsportMatch _match({
  String id = 'm1',
  bool finished = true,
  String? phase,
  int? matchCost,
}) {
  return GNEsportMatch(
    id: id,
    homeTeamId: 'u1',
    awayTeamId: 'u2',
    homeScore: finished ? 2 : null,
    awayScore: finished ? 1 : null,
    date: DateTime(2026, 1, 1),
    isFinished: finished,
    leagueId: 'l1',
    phase: phase,
    matchCost: matchCost,
    homeTeam: _user('u1', 'Alice'),
    awayTeam: _user('u2', 'Bob'),
  );
}

Widget _wrap(TournamentDetailBloc bloc) {
  return MaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<TournamentDetailBloc>.value(
      value: bloc,
      child: const TournamentDetailView(),
    ),
  );
}

void main() {
  late _MockBloc bloc;
  late _MockRemoteConfig remoteConfig;

  setUpAll(() {
    registerFallbackValue(ChangeLeagueStatus(GNEsportLeagueStatus.ongoing));
    registerFallbackValue(GetParticipantsAndMatches('l1'));
    registerFallbackValue(const GenerateRound());
    registerFallbackValue(RecomputeStats());
    registerFallbackValue(InactiveLeague());
    registerFallbackValue(SubmitLeagueStatus());
  });

  setUp(() {
    bloc = _MockBloc();
    remoteConfig = _MockRemoteConfig();
    when(() => remoteConfig.adsEnabled).thenReturn(false);
    if (GetIt.instance.isRegistered<GNRemoteConfig>()) {
      GetIt.instance.unregister<GNRemoteConfig>();
    }
    GetIt.instance.registerSingleton<GNRemoteConfig>(remoteConfig);
  });

  tearDown(() async {
    await bloc.close();
    if (GetIt.instance.isRegistered<GNRemoteConfig>()) {
      GetIt.instance.unregister<GNRemoteConfig>();
    }
  });

  testWidgets(
    'renders league mode hero, tabs, loading overlay and add dialog',
    (tester) async {
      final state = _DetailState(
        viewStatus: ViewStatus.loading,
        league: _league(name: ''),
        participants: [_stat('u1', 'Alice', 2), _stat('u2', 'Bob', 1)],
        matches: [
          _match(finished: false),
          _match(id: 'm2'),
        ],
        users: [_user('u1', 'Alice'), _user('u2', 'Bob')],
        member: true,
        admin: true,
      );
      when(() => bloc.state).thenReturn(state);
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(_wrap(bloc));

      expect(find.textContaining('Group One'), findsWidgets);
      expect(find.text('BXH'), findsOneWidget);
      expect(find.text('Lịch'), findsOneWidget);
      expect(find.text('Kết quả'), findsOneWidget);
      expect(find.text('Chi phí'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      expect(find.byIcon(Icons.person_add_outlined), findsOneWidget);
    },
  );

  testWidgets('admin menu changes status, recomputes and deletes', (
    tester,
  ) async {
    final state = _DetailState(
      league: _league(),
      participants: [_stat('u1', 'Alice', 2), _stat('u2', 'Bob', 1)],
      matches: [_match()],
      member: true,
      admin: true,
    );
    when(() => bloc.state).thenReturn(state);
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc));

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trạng thái').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    verify(() => bloc.add(any(that: isA<SubmitLeagueStatus>()))).called(1);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đồng bộ điểm số'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đồng bộ'));
    await tester.pumpAndSettle();
    verify(() => bloc.add(any(that: isA<RecomputeStats>()))).called(1);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa giải đấu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá'));
    await tester.pumpAndSettle();
    verify(() => bloc.add(any(that: isA<InactiveLeague>()))).called(1);
  });

  testWidgets('renders cup and full mode tab sets', (tester) async {
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => bloc.state,
    ).thenReturn(_DetailState(league: _league(mode: TournamentMode.cup)));
    await tester.pumpWidget(_wrap(bloc));
    expect(find.text('Bracket'), findsOneWidget);
    expect(find.text('Kết quả'), findsOneWidget);
    expect(find.text('Chi phí'), findsOneWidget);

    await bloc.close();
    bloc = _MockBloc();
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => bloc.state,
    ).thenReturn(_DetailState(league: _league(mode: TournamentMode.full)));
    await tester.pumpWidget(_wrap(bloc));
    await tester.pump();
    expect(find.text('Bảng'), findsWidgets);
    expect(find.text('Bracket'), findsOneWidget);
  });

  testWidgets('lifecycle resume refreshes current league', (tester) async {
    when(() => bloc.state).thenReturn(_DetailState(league: _league()));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    verify(
      () => bloc.add(any(that: isA<GetParticipantsAndMatches>())),
    ).called(1);
  });
}
