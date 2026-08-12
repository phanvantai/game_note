import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/domain/repositories/esport/esport_group_repository.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_firestore_esport_league_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/round_robin_scheduler.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/l10n/app_text.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart';

class _MockRepo extends Mock implements EsportLeagueRepository {}

class _MockGroupRepo extends Mock implements EsportGroupRepository {}

class _FakeMatch extends Fake implements GNEsportMatch {}

class _FakeLeague extends Fake implements GNEsportLeague {}

class _RecordingBlocObserver extends BlocObserver {
  final List<Object?> events = [];

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    if (bloc is TournamentDetailBloc) events.add(event);
  }
}

class _LeagueStreams {
  final league = StreamController<GNEsportLeague?>.broadcast();
  final stats = StreamController<List<GNEsportLeagueStat>>.broadcast();
  final matches = StreamController<List<GNEsportMatch>>.broadcast();

  Future<void> close() async {
    await league.close();
    await stats.close();
    await matches.close();
  }
}

void _stubStreams(_MockRepo repo, _LeagueStreams streams, String leagueId) {
  when(
    () => repo.listenForLeagueUpdated(leagueId),
  ).thenAnswer((_) => streams.league.stream);
  when(
    () => repo.listenForLeagueStats(leagueId),
  ).thenAnswer((_) => streams.stats.stream);
  when(
    () => repo.listenForMatchesUpdated(leagueId),
  ).thenAnswer((_) => streams.matches.stream);
}

GNEsportLeague _league({
  String id = 'L1',
  String groupId = 'G1',
  String name = 'L',
  String? status,
  bool rankPayoutEnabled = false,
  List<int> rankPayouts = const [],
  int defaultMatchCost = 50000,
  bool isActive = true,
  List<String> participants = const [],
  GNEsportGroup? group,
}) {
  return GNEsportLeague(
    id: id,
    ownerId: 'owner',
    groupId: groupId,
    name: name,
    startDate: DateTime(2026, 1, 1),
    isActive: isActive,
    description: '',
    participants: participants,
    group: group,
    status: status,
    rankPayoutEnabled: rankPayoutEnabled,
    rankPayouts: rankPayouts,
    defaultMatchCost: defaultMatchCost,
  );
}

GNEsportMatch _match({
  String id = 'M1',
  String home = 'A',
  String away = 'B',
  String leagueId = 'L1',
  bool isFinished = false,
  int? homeScore,
  int? awayScore,
  int? matchCost,
  int? costPerGoal,
  String? phase,
}) {
  return GNEsportMatch(
    id: id,
    homeTeamId: home,
    awayTeamId: away,
    homeScore: homeScore,
    awayScore: awayScore,
    date: DateTime(2026, 1, 1),
    isFinished: isFinished,
    leagueId: leagueId,
    matchCost: matchCost,
    costPerGoal: costPerGoal,
    phase: phase,
  );
}

GNEsportLeagueStat _stat(
  String userId, {
  String leagueId = 'L1',
  String? groupId,
  int wins = 0,
  int draws = 0,
  int losses = 0,
  int goals = 0,
  int goalsConceded = 0,
  GNUser? user,
}) {
  return GNEsportLeagueStat(
    id: 'S_$userId',
    userId: userId,
    leagueId: leagueId,
    matchesPlayed: wins + draws + losses,
    goals: goals,
    goalsConceded: goalsConceded,
    wins: wins,
    draws: draws,
    losses: losses,
    groupId: groupId,
    user: user,
  );
}

GNUser _user(String id, {String? name}) {
  return GNUser(
    id: id,
    email: '$id@test',
    displayName: name ?? id,
    photoUrl: null,
    phoneNumber: null,
    role: 'user',
  );
}

GNEsportGroup _group(String id) {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  return GNEsportGroup(
    id: id,
    groupName: id,
    ownerId: 'owner',
    members: const [],
    description: '',
    createdAt: epoch,
    updatedAt: epoch,
    status: 'active',
  );
}

Future<void> _flush([int turns = 8]) async {
  for (var i = 0; i < turns; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<TournamentDetailState> _waitForState(
  TournamentDetailBloc bloc,
  bool Function(TournamentDetailState state) predicate,
) async {
  if (predicate(bloc.state)) return bloc.state;
  return bloc.stream.firstWhere(predicate).timeout(const Duration(seconds: 2));
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeMatch());
    registerFallbackValue(_FakeLeague());
  });

  late _MockRepo repo;
  late _MockGroupRepo groupRepo;
  late List<String> toasts;

  setUp(() {
    repo = _MockRepo();
    groupRepo = _MockGroupRepo();
    toasts = [];
    setShowToastImpl((msg, {gravity = ToastGravity.BOTTOM}) => toasts.add(msg));

    // Streams thường được listen ở init flows — stub bằng empty stream để
    // các handler nào subscribe không crash.
    when(
      () => repo.listenForLeagueStats(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => repo.listenForMatchesUpdated(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => repo.listenForLeagueUpdated(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(() => repo.getUsersByIds(any())).thenAnswer((_) async => const {});
    when(() => groupRepo.getGroup(any())).thenAnswer(
      (invocation) async => _group(invocation.positionalArguments[0] as String),
    );
  });

  tearDown(() {
    resetShowToast();
  });

  TournamentDetailBloc build() => TournamentDetailBloc(repo, groupRepo);

  TournamentDetailBloc buildWithLeague(GNEsportLeague league) {
    final bloc = TournamentDetailBloc(repo, groupRepo);
    bloc.emit(bloc.state.copyWith(league: league));
    return bloc;
  }

  void verifyNoExplicitDetailReads() {
    verifyNever(() => repo.getLeague(any()));
    verifyNever(() => repo.getLeagueStats(any()));
    verifyNever(() => repo.getMatches(any()));
  }

  group('stream-only league detail lifecycle', () {
    test(
      'OpenLeagueDetail attaches exactly three streams and performs no reads',
      () async {
        final streams = _LeagueStreams();
        addTearDown(streams.close);
        _stubStreams(repo, streams, 'L1');
        final bloc = build();
        addTearDown(bloc.close);

        bloc.add(const OpenLeagueDetail('L1'));
        await _flush();

        verify(() => repo.listenForLeagueUpdated('L1')).called(1);
        verify(() => repo.listenForLeagueStats('L1')).called(1);
        verify(() => repo.listenForMatchesUpdated('L1')).called(1);
        verifyNoExplicitDetailReads();
        expect(bloc.state.bootstrapStatus, DetailBootstrapStatus.loading);
      },
    );

    test(
      'initial snapshots patch independent slices before bootstrap is ready',
      () async {
        final streams = _LeagueStreams();
        addTearDown(streams.close);
        _stubStreams(repo, streams, 'L1');
        final bloc = build();
        addTearDown(bloc.close);
        bloc.add(const OpenLeagueDetail('L1'));
        await _flush();

        streams.league.add(_league(participants: const []));
        await _waitForState(
          bloc,
          (s) => s.leagueSliceStatus == DetailSliceStatus.ready,
        );
        expect(bloc.state.league?.id, 'L1');
        expect(bloc.state.statsSliceStatus, DetailSliceStatus.waiting);
        expect(bloc.state.matchesSliceStatus, DetailSliceStatus.waiting);
        expect(bloc.state.participants, isEmpty);
        expect(bloc.state.matches, isEmpty);

        streams.matches.add([_match()]);
        await _waitForState(
          bloc,
          (s) => s.matchesSliceStatus == DetailSliceStatus.ready,
        );
        expect(bloc.state.matches.single.id, 'M1');
        expect(bloc.state.statsSliceStatus, DetailSliceStatus.waiting);

        streams.stats.add([_stat('A')]);
        await _waitForState(
          bloc,
          (s) => s.bootstrapStatus == DetailBootstrapStatus.ready,
        );
        expect(bloc.state.participants.single.userId, 'A');
        expect(bloc.state.league?.id, 'L1');
        expect(bloc.state.matches.single.id, 'M1');
        expect(bloc.state.viewStatus, isNot(ViewStatus.loading));
      },
    );

    test(
      'subsequent remote snapshots update only their slice without reads, loading, or toast',
      () async {
        final streams = _LeagueStreams();
        addTearDown(streams.close);
        _stubStreams(repo, streams, 'L1');
        final bloc = build();
        addTearDown(bloc.close);
        bloc.add(const OpenLeagueDetail('L1'));
        await _flush();
        streams.league.add(_league(name: 'Before'));
        streams.stats.add([_stat('A')]);
        streams.matches.add([_match(homeScore: 0, awayScore: 0)]);
        await _waitForState(
          bloc,
          (s) => s.bootstrapStatus == DetailBootstrapStatus.ready,
        );
        clearInteractions(repo);
        toasts.clear();

        streams.league.add(_league(name: 'After'));
        await _waitForState(bloc, (s) => s.league?.name == 'After');
        expect(bloc.state.participants.single.userId, 'A');
        expect(bloc.state.matches.single.homeScore, 0);

        streams.stats.add([_stat('A', wins: 1)]);
        await _waitForState(bloc, (s) => s.participants.single.wins == 1);
        expect(bloc.state.league?.name, 'After');
        expect(bloc.state.matches.single.homeScore, 0);

        streams.matches.add([
          _match(homeScore: 3, awayScore: 2, isFinished: true),
        ]);
        await _waitForState(bloc, (s) => s.matches.single.homeScore == 3);
        expect(bloc.state.league?.name, 'After');
        expect(bloc.state.participants.single.wins, 1);
        verifyNoExplicitDetailReads();
        expect(toasts, isEmpty);
        expect(bloc.state.viewStatus, isNot(ViewStatus.loading));
      },
    );

    test(
      'user cache fetches only missing roster IDs and ignores score, cost, and name-only updates',
      () async {
        final streams = _LeagueStreams();
        addTearDown(streams.close);
        _stubStreams(repo, streams, 'L1');
        when(() => repo.getUsersByIds(any())).thenAnswer((invocation) async {
          final ids = invocation.positionalArguments.single as List<String>;
          return {for (final id in ids) id: _user(id)};
        });
        final bloc = build();
        addTearDown(bloc.close);
        bloc.add(const OpenLeagueDetail('L1'));
        await _flush();

        streams.league.add(_league(participants: const ['A', 'B']));
        streams.stats.add([_stat('A'), _stat('B')]);
        streams.matches.add([_match(home: 'A', away: 'B')]);
        await _waitForState(bloc, (s) => s.usersById.length == 2);
        final firstBatch = verify(
          () => repo.getUsersByIds(captureAny()),
        ).captured;
        expect((firstBatch.single as List<String>).toSet(), {'A', 'B'});

        streams.league.add(
          _league(name: 'Renamed', participants: const ['A', 'B']),
        );
        streams.stats.add([_stat('A', goals: 2), _stat('B')]);
        streams.matches.add([
          _match(
            home: 'A',
            away: 'B',
            homeScore: 2,
            awayScore: 0,
            matchCost: 90000,
            isFinished: true,
          ),
        ]);
        await _waitForState(bloc, (s) => s.matches.single.matchCost == 90000);
        verifyNever(() => repo.getUsersByIds(any()));

        streams.matches.add([_match(id: 'M2', home: 'A', away: 'C')]);
        await _waitForState(bloc, (s) => s.usersById.containsKey('C'));
        final secondBatch = verify(
          () => repo.getUsersByIds(captureAny()),
        ).captured;
        expect(secondBatch.single, ['C']);
        expect(bloc.state.matches.single.awayTeam?.id, 'C');
      },
    );

    test(
      'user cache race late L1 completion cannot clear the in-flight L2 marker',
      () async {
        final l1 = _LeagueStreams();
        final l2 = _LeagueStreams();
        addTearDown(l1.close);
        addTearDown(l2.close);
        _stubStreams(repo, l1, 'L1');
        _stubStreams(repo, l2, 'L2');
        final l1Started = Completer<void>();
        final l2Started = Completer<void>();
        final duplicateStarted = Completer<void>();
        final l1Users = Completer<Map<String, GNUser>>();
        final l2Users = Completer<Map<String, GNUser>>();
        final duplicateUsers = Completer<Map<String, GNUser>>();
        final batches = <List<String>>[];
        when(() => repo.getUsersByIds(any())).thenAnswer((invocation) {
          final ids = List<String>.of(
            invocation.positionalArguments.single as List<String>,
          );
          batches.add(ids);
          switch (batches.length) {
            case 1:
              l1Started.complete();
              return l1Users.future;
            case 2:
              l2Started.complete();
              return l2Users.future;
            default:
              if (!duplicateStarted.isCompleted) duplicateStarted.complete();
              return duplicateUsers.future;
          }
        });
        final bloc = build();
        addTearDown(bloc.close);
        addTearDown(() {
          if (!l1Users.isCompleted) l1Users.complete(const {});
          if (!l2Users.isCompleted) l2Users.complete(const {});
          if (!duplicateUsers.isCompleted) duplicateUsers.complete(const {});
        });

        bloc.add(const OpenLeagueDetail('L1'));
        await _flush();
        l1.league.add(_league(participants: const ['A'], group: _group('G1')));
        await l1Started.future.timeout(const Duration(seconds: 1));
        expect(batches, [
          ['A'],
        ]);

        bloc.add(const OpenLeagueDetail('L2'));
        await _flush(20);
        l2.league.add(
          _league(
            id: 'L2',
            groupId: 'G2',
            participants: const ['A'],
            group: _group('G2'),
          ),
        );
        await l2Started.future.timeout(const Duration(seconds: 1));
        expect(batches, [
          ['A'],
          ['A'],
        ]);

        l1Users.complete({'A': _user('A', name: 'stale L1')});
        await _flush(20);
        expect(bloc.state.league?.id, 'L2');
        expect(bloc.state.usersById, isEmpty);

        l2.league.add(
          _league(
            id: 'L2',
            groupId: 'G2',
            name: 'L2 second snapshot',
            participants: const ['A'],
            group: _group('G2'),
          ),
        );
        await _flush(20);

        expect(batches, hasLength(2));
        expect(duplicateStarted.isCompleted, isFalse);
        verify(() => repo.getUsersByIds(['A'])).called(2);

        l2Users.complete({'A': _user('A', name: 'current L2')});
        await _waitForState(
          bloc,
          (s) => s.usersById['A']?.displayName == 'current L2',
        );
        expect(bloc.state.league?.id, 'L2');
        expect(bloc.state.usersById['A']?.displayName, 'current L2');
      },
    );

    test(
      'group cache reuses embedded group and fetches a new groupId once',
      () async {
        final streams = _LeagueStreams();
        addTearDown(streams.close);
        _stubStreams(repo, streams, 'L1');
        when(
          () => groupRepo.getGroup('G2'),
        ).thenAnswer((_) async => _group('G2'));
        final bloc = build();
        addTearDown(bloc.close);
        bloc.add(const OpenLeagueDetail('L1'));
        await _flush();

        streams.league.add(_league(group: _group('G1')));
        await _waitForState(bloc, (s) => s.league?.group?.id == 'G1');
        streams.league.add(_league(name: 'same group', group: _group('G1')));
        await _waitForState(bloc, (s) => s.league?.name == 'same group');
        verifyNever(() => groupRepo.getGroup('G1'));

        streams.league.add(_league(groupId: 'G2'));
        await _waitForState(bloc, (s) => s.league?.group?.id == 'G2');
        streams.league.add(_league(groupId: 'G2', name: 'G2 renamed'));
        await _waitForState(bloc, (s) => s.league?.name == 'G2 renamed');
        verify(() => groupRepo.getGroup('G2')).called(1);
        verifyNever(() => repo.getLeague(any()));
      },
    );

    test(
      'EnsureDetailSubscriptions keeps active listeners and only bumps refreshTick',
      () async {
        final streams = _LeagueStreams();
        addTearDown(streams.close);
        _stubStreams(repo, streams, 'L1');
        final bloc = build();
        addTearDown(bloc.close);
        bloc.add(const OpenLeagueDetail('L1'));
        await _flush();
        final before = bloc.state.refreshTick;

        bloc.add(const EnsureDetailSubscriptions('L1'));
        await _waitForState(bloc, (s) => s.refreshTick == before + 1);

        verify(() => repo.listenForLeagueUpdated('L1')).called(1);
        verify(() => repo.listenForLeagueStats('L1')).called(1);
        verify(() => repo.listenForMatchesUpdated('L1')).called(1);
      },
    );

    test(
      'EnsureDetailSubscriptions rebinds only the slice that completed',
      () async {
        final firstStats =
            StreamController<List<GNEsportLeagueStat>>.broadcast();
        final secondStats =
            StreamController<List<GNEsportLeagueStat>>.broadcast();
        final streams = _LeagueStreams();
        addTearDown(() async {
          await firstStats.close();
          await secondStats.close();
          await streams.league.close();
          await streams.matches.close();
        });
        var statsListens = 0;
        when(() => repo.listenForLeagueStats('L1')).thenAnswer(
          (_) => statsListens++ == 0 ? firstStats.stream : secondStats.stream,
        );
        when(
          () => repo.listenForLeagueUpdated('L1'),
        ).thenAnswer((_) => streams.league.stream);
        when(
          () => repo.listenForMatchesUpdated('L1'),
        ).thenAnswer((_) => streams.matches.stream);
        final bloc = build();
        addTearDown(bloc.close);
        bloc.add(const OpenLeagueDetail('L1'));
        await _flush();

        await firstStats.close();
        await _flush();
        final refreshTickBeforeRebind = bloc.state.refreshTick;
        bloc.add(const EnsureDetailSubscriptions('L1'));
        await _waitForState(
          bloc,
          (s) => s.refreshTick == refreshTickBeforeRebind + 1,
        );
        await _flush();

        verify(() => repo.listenForLeagueStats('L1')).called(2);
        verify(() => repo.listenForLeagueUpdated('L1')).called(1);
        verify(() => repo.listenForMatchesUpdated('L1')).called(1);
        expect(bloc.state.refreshTick, refreshTickBeforeRebind + 1);
        expect(secondStats.hasListener, isTrue);
      },
    );

    test(
      'stream errors preserve other slices and retry at most three times',
      () async {
        final leagueStreams = <StreamController<GNEsportLeague?>>[];
        var leagueListens = 0;
        when(() => repo.listenForLeagueUpdated('L1')).thenAnswer((_) {
          final controller = StreamController<GNEsportLeague?>.broadcast();
          leagueStreams.add(controller);
          leagueListens++;
          return controller.stream;
        });
        final stable = _LeagueStreams();
        addTearDown(() async {
          for (final controller in leagueStreams) {
            await controller.close();
          }
          await stable.stats.close();
          await stable.matches.close();
        });
        when(
          () => repo.listenForLeagueStats('L1'),
        ).thenAnswer((_) => stable.stats.stream);
        when(
          () => repo.listenForMatchesUpdated('L1'),
        ).thenAnswer((_) => stable.matches.stream);
        final bloc = build();
        addTearDown(bloc.close);
        bloc.add(const OpenLeagueDetail('L1'));
        await _flush();
        stable.stats.add([_stat('A')]);
        stable.matches.add([_match()]);
        await _waitForState(
          bloc,
          (s) =>
              s.statsSliceStatus == DetailSliceStatus.ready &&
              s.matchesSliceStatus == DetailSliceStatus.ready,
        );

        leagueStreams[0].addError(Exception('league stream down'));
        await _waitForState(
          bloc,
          (s) => s.streamErrors.containsKey(TournamentDetailSlice.league),
        );
        expect(bloc.state.participants.single.userId, 'A');
        expect(bloc.state.matches.single.id, 'M1');
        expect(leagueListens, 1);

        await Future<void>.delayed(const Duration(milliseconds: 1100));
        expect(leagueListens, 2);
        leagueStreams[1].addError(Exception('again'));
        await Future<void>.delayed(const Duration(milliseconds: 2100));
        expect(leagueListens, 3);
        leagueStreams[2].addError(Exception('again'));
        await Future<void>.delayed(const Duration(milliseconds: 4100));
        expect(leagueListens, 4);
        leagueStreams[3].addError(Exception('terminal'));
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        expect(leagueListens, 4);
        expect(bloc.state.streamErrors, contains(TournamentDetailSlice.league));
      },
      timeout: const Timeout(Duration(seconds: 12)),
    );

    test(
      'successful snapshot resets retry state for the next error',
      () async {
        final controllers = <StreamController<GNEsportLeague?>>[];
        when(() => repo.listenForLeagueUpdated('L1')).thenAnswer((_) {
          final controller = StreamController<GNEsportLeague?>.broadcast();
          controllers.add(controller);
          return controller.stream;
        });
        final stable = _LeagueStreams();
        addTearDown(() async {
          for (final controller in controllers) {
            await controller.close();
          }
          await stable.stats.close();
          await stable.matches.close();
        });
        when(
          () => repo.listenForLeagueStats('L1'),
        ).thenAnswer((_) => stable.stats.stream);
        when(
          () => repo.listenForMatchesUpdated('L1'),
        ).thenAnswer((_) => stable.matches.stream);
        final bloc = build();
        addTearDown(bloc.close);
        bloc.add(const OpenLeagueDetail('L1'));
        await _flush();
        controllers[0].addError(Exception('first'));
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        expect(controllers, hasLength(2));
        controllers[1].add(_league());
        await _waitForState(
          bloc,
          (s) => s.leagueSliceStatus == DetailSliceStatus.ready,
        );
        controllers[1].addError(Exception('after recovery'));
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        expect(controllers, hasLength(3));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    test('close cancels listeners and pending retry timers', () async {
      final streams = _LeagueStreams();
      addTearDown(streams.close);
      _stubStreams(repo, streams, 'L1');
      final bloc = build();
      bloc.add(const OpenLeagueDetail('L1'));
      await _flush();
      streams.league.addError(Exception('down'));
      await _waitForState(
        bloc,
        (s) => s.streamErrors.containsKey(TournamentDetailSlice.league),
      );

      await bloc.close();
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      verify(() => repo.listenForLeagueUpdated('L1')).called(1);
      expect(bloc.isClosed, isTrue);
      expect(streams.league.hasListener, isFalse);
      expect(streams.stats.hasListener, isFalse);
      expect(streams.matches.hasListener, isFalse);
    });

    test(
      'race latest open wins while previous subscription cancellation is suspended',
      () async {
        final cancelStarted = Completer<void>();
        final releaseCancel = Completer<void>();
        final l1League = StreamController<GNEsportLeague?>(
          onCancel: () {
            if (!cancelStarted.isCompleted) cancelStarted.complete();
            return releaseCancel.future;
          },
        );
        final l1Stats = StreamController<List<GNEsportLeagueStat>>.broadcast();
        final l1Matches = StreamController<List<GNEsportMatch>>.broadcast();
        final l2 = _LeagueStreams();
        final l3 = _LeagueStreams();
        addTearDown(() async {
          if (!releaseCancel.isCompleted) releaseCancel.complete();
          await l1League.close();
          await l1Stats.close();
          await l1Matches.close();
          await l2.close();
          await l3.close();
        });
        when(
          () => repo.listenForLeagueUpdated('L1'),
        ).thenAnswer((_) => l1League.stream);
        when(
          () => repo.listenForLeagueStats('L1'),
        ).thenAnswer((_) => l1Stats.stream);
        when(
          () => repo.listenForMatchesUpdated('L1'),
        ).thenAnswer((_) => l1Matches.stream);
        _stubStreams(repo, l2, 'L2');
        _stubStreams(repo, l3, 'L3');
        final bloc = build();
        addTearDown(bloc.close);
        bloc.add(const OpenLeagueDetail('L1'));
        await _flush();
        expect(l1League.hasListener, isTrue);

        bloc.add(const OpenLeagueDetail('L2'));
        await cancelStarted.future.timeout(const Duration(seconds: 1));
        bloc.add(const OpenLeagueDetail('L3'));
        await _flush();
        expect(l3.league.hasListener, isTrue);

        releaseCancel.complete();
        await _flush(20);

        verifyNever(() => repo.listenForLeagueUpdated('L2'));
        verifyNever(() => repo.listenForLeagueStats('L2'));
        verifyNever(() => repo.listenForMatchesUpdated('L2'));
        verify(() => repo.listenForLeagueUpdated('L3')).called(1);
        verify(() => repo.listenForLeagueStats('L3')).called(1);
        verify(() => repo.listenForMatchesUpdated('L3')).called(1);
        expect(l2.league.hasListener, isFalse);
        expect(l2.stats.hasListener, isFalse);
        expect(l2.matches.hasListener, isFalse);
        expect(l3.league.hasListener, isTrue);

        l3.league.add(_league(id: 'L3', groupId: 'G3', group: _group('G3')));
        await _flush(20);
        expect(bloc.state.league?.id, 'L3');
        l1League.add(_league(id: 'L1', name: 'stale L1'));
        l2.league.add(_league(id: 'L2', name: 'stale L2'));
        await _flush();
        expect(bloc.state.league?.id, 'L3');
      },
    );

    test(
      'race close during suspended open never attaches the next league',
      () async {
        final cancelStarted = Completer<void>();
        final releaseCancel = Completer<void>();
        final l1League = StreamController<GNEsportLeague?>(
          onCancel: () {
            if (!cancelStarted.isCompleted) cancelStarted.complete();
            return releaseCancel.future;
          },
        );
        final l1Stats = StreamController<List<GNEsportLeagueStat>>.broadcast();
        final l1Matches = StreamController<List<GNEsportMatch>>.broadcast();
        final l2 = _LeagueStreams();
        addTearDown(() async {
          if (!releaseCancel.isCompleted) releaseCancel.complete();
          await l1League.close();
          await l1Stats.close();
          await l1Matches.close();
          await l2.close();
        });
        when(
          () => repo.listenForLeagueUpdated('L1'),
        ).thenAnswer((_) => l1League.stream);
        when(
          () => repo.listenForLeagueStats('L1'),
        ).thenAnswer((_) => l1Stats.stream);
        when(
          () => repo.listenForMatchesUpdated('L1'),
        ).thenAnswer((_) => l1Matches.stream);
        _stubStreams(repo, l2, 'L2');
        final bloc = build();
        bloc.add(const OpenLeagueDetail('L1'));
        await _flush();

        bloc.add(const OpenLeagueDetail('L2'));
        await cancelStarted.future.timeout(const Duration(seconds: 1));
        final closeFuture = bloc.close();
        releaseCancel.complete();
        await closeFuture.timeout(const Duration(seconds: 1));
        await _flush(20);

        expect(bloc.isClosed, isTrue);
        verifyNever(() => repo.listenForLeagueUpdated('L2'));
        verifyNever(() => repo.listenForLeagueStats('L2'));
        verifyNever(() => repo.listenForMatchesUpdated('L2'));
        expect(l2.league.hasListener, isFalse);
        expect(l2.stats.hasListener, isFalse);
        expect(l2.matches.hasListener, isFalse);
      },
    );

    test(
      'race queued Ensure during suspended close cannot reopen another league',
      () async {
        final cancelStarted = Completer<void>();
        final releaseCancel = Completer<void>();
        final l1League = StreamController<GNEsportLeague?>(
          onCancel: () {
            if (!cancelStarted.isCompleted) cancelStarted.complete();
            return releaseCancel.future;
          },
        );
        final l1Stats = StreamController<List<GNEsportLeagueStat>>.broadcast();
        final l1Matches = StreamController<List<GNEsportMatch>>.broadcast();
        final l2 = _LeagueStreams();
        final uncaughtErrors = <Object>[];
        final observer = _RecordingBlocObserver();
        final previousObserver = Bloc.observer;
        Bloc.observer = observer;
        late TournamentDetailBloc bloc;
        addTearDown(() => Bloc.observer = previousObserver);
        addTearDown(() async {
          if (!releaseCancel.isCompleted) releaseCancel.complete();
          await l1League.close();
          await l1Stats.close();
          await l1Matches.close();
          await l2.close();
        });
        when(
          () => repo.listenForLeagueUpdated('L1'),
        ).thenAnswer((_) => l1League.stream);
        when(
          () => repo.listenForLeagueStats('L1'),
        ).thenAnswer((_) => l1Stats.stream);
        when(
          () => repo.listenForMatchesUpdated('L1'),
        ).thenAnswer((_) => l1Matches.stream);
        _stubStreams(repo, l2, 'L2');

        await runZonedGuarded<Future<void>>(() async {
          bloc = build();
          bloc.add(const OpenLeagueDetail('L1'));
          await _flush();
          observer.events.clear();
          final closeFuture = bloc.close();
          await cancelStarted.future.timeout(const Duration(seconds: 1));

          bloc.add(const EnsureDetailSubscriptions('L2'));
          await _flush(20);
          releaseCancel.complete();
          await closeFuture.timeout(const Duration(seconds: 1));

          l2.league.add(_league(id: 'L2', groupId: 'G2', group: _group('G2')));
          await _flush(20);
        }, (error, _) => uncaughtErrors.add(error));

        expect(bloc.isClosed, isTrue);
        expect(uncaughtErrors, isEmpty);
        expect(
          observer.events.whereType<OpenLeagueDetail>(),
          isEmpty,
          reason: 'Ensure queued during close must not enqueue a new open',
        );
        verifyNever(() => repo.listenForLeagueUpdated('L2'));
        verifyNever(() => repo.listenForLeagueStats('L2'));
        verifyNever(() => repo.listenForMatchesUpdated('L2'));
        expect(l2.league.hasListener, isFalse);
        expect(l2.stats.hasListener, isFalse);
        expect(l2.matches.hasListener, isFalse);
      },
    );

    test(
      'latest group snapshot wins when an older same-league lookup completes later',
      () async {
        final streams = _LeagueStreams();
        addTearDown(streams.close);
        _stubStreams(repo, streams, 'L1');
        final g1LookupStarted = Completer<void>();
        final g1Result = Completer<GNEsportGroup?>();
        when(() => groupRepo.getGroup('G1')).thenAnswer((_) {
          g1LookupStarted.complete();
          return g1Result.future;
        });
        when(
          () => groupRepo.getGroup('G2'),
        ).thenAnswer((_) async => _group('G2'));
        final bloc = build();
        addTearDown(bloc.close);
        bloc.add(const OpenLeagueDetail('L1'));
        await _flush();

        streams.league.add(_league(groupId: 'G1', name: 'older'));
        await g1LookupStarted.future.timeout(const Duration(seconds: 1));
        streams.league.add(_league(groupId: 'G2', name: 'newer'));
        await _waitForState(
          bloc,
          (s) => s.league?.name == 'newer' && s.league?.group?.id == 'G2',
        );

        g1Result.complete(_group('G1'));
        await _flush(20);

        expect(bloc.state.league?.name, 'newer');
        expect(bloc.state.league?.groupId, 'G2');
        expect(bloc.state.league?.group?.id, 'G2');
        verify(() => groupRepo.getGroup('G1')).called(1);
        verify(() => groupRepo.getGroup('G2')).called(1);
      },
    );

    test(
      'race direct LeagueDeleted terminally cancels listeners, retries, and stale snapshots',
      () async {
        final streams = _LeagueStreams();
        addTearDown(streams.close);
        _stubStreams(repo, streams, 'L1');
        final bloc = build();
        addTearDown(bloc.close);
        bloc.add(const OpenLeagueDetail('L1'));
        await _flush();
        streams.league.add(_league(group: _group('G1')));
        await _waitForState(bloc, (s) => s.league?.id == 'L1');
        streams.stats.addError(Exception('stats down'));
        await _waitForState(
          bloc,
          (s) => s.streamErrors.containsKey(TournamentDetailSlice.stats),
        );

        bloc.add(LeagueDeleted());
        await _waitForState(bloc, (s) => s.leagueDeleted);
        streams.league.add(_league(name: 'zombie', group: _group('G1')));
        await _flush(20);

        expect(streams.league.hasListener, isFalse);
        expect(streams.stats.hasListener, isFalse);
        expect(streams.matches.hasListener, isFalse);
        expect(bloc.state.leagueDeleted, isTrue);
        expect(bloc.state.league, isNull);
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        verify(() => repo.listenForLeagueStats('L1')).called(1);
      },
      timeout: const Timeout(Duration(seconds: 3)),
    );

    test(
      'opening a different league cancels old streams and clears caches',
      () async {
        final l1 = _LeagueStreams();
        final l2 = _LeagueStreams();
        addTearDown(l1.close);
        addTearDown(l2.close);
        _stubStreams(repo, l1, 'L1');
        _stubStreams(repo, l2, 'L2');
        when(() => repo.getUsersByIds(any())).thenAnswer((invocation) async {
          final ids = invocation.positionalArguments.single as List<String>;
          return {for (final id in ids) id: _user(id)};
        });
        final bloc = build();
        addTearDown(bloc.close);
        bloc.add(const OpenLeagueDetail('L1'));
        await _flush();
        l1.league.add(_league(participants: const ['A'], group: _group('G1')));
        await _waitForState(bloc, (s) => s.usersById.containsKey('A'));

        bloc.add(const OpenLeagueDetail('L2'));
        await _flush();

        expect(l1.league.hasListener, isFalse);
        expect(l1.stats.hasListener, isFalse);
        expect(l1.matches.hasListener, isFalse);
        expect(bloc.state.usersById, isEmpty);
        expect(bloc.state.league, isNull);
        verify(() => repo.listenForLeagueUpdated('L2')).called(1);
        verify(() => repo.listenForLeagueStats('L2')).called(1);
        verify(() => repo.listenForMatchesUpdated('L2')).called(1);
        l2.league.add(_league(id: 'L2', groupId: 'G1'));
        await _waitForState(
          bloc,
          (s) => s.league?.id == 'L2' && s.league?.group?.id == 'G1',
        );
        verify(() => groupRepo.getGroup('G1')).called(1);
      },
    );

    test(
      'null league marks deletion while inactive metadata stays quiet',
      () async {
        final streams = _LeagueStreams();
        addTearDown(streams.close);
        _stubStreams(repo, streams, 'L1');
        final bloc = build();
        addTearDown(bloc.close);
        bloc.add(const OpenLeagueDetail('L1'));
        await _flush();
        streams.league.add(_league(isActive: false));
        await _waitForState(bloc, (s) => s.league?.isActive == false);
        expect(bloc.state.leagueDeleted, isFalse);
        expect(bloc.state.viewStatus, isNot(ViewStatus.loading));
        expect(toasts, isEmpty);

        streams.league.add(null);
        await _waitForState(bloc, (s) => s.leagueDeleted);
        expect(bloc.state.bootstrapStatus, DetailBootstrapStatus.failure);
        expect(bloc.state.league, isNull);
      },
    );
  });

  group('atomic match pending and multi-client reconciliation', () {
    test(
      'M1 pending does not block M2 and unresolved write has no success toast',
      () async {
        final streams = _LeagueStreams();
        addTearDown(streams.close);
        _stubStreams(repo, streams, 'L1');
        final m1Write = Completer<void>();
        when(() => repo.updateMatchAtomically(any())).thenAnswer((invocation) {
          final match = invocation.positionalArguments.single as GNEsportMatch;
          return match.id == 'M1' ? m1Write.future : Future<void>.value();
        });
        final bloc = build();
        addTearDown(bloc.close);
        bloc.add(const OpenLeagueDetail('L1'));
        await _flush();
        streams.league.add(_league());
        streams.stats.add([_stat('A'), _stat('B')]);
        streams.matches.add([_match(id: 'M1'), _match(id: 'M2')]);
        await _waitForState(
          bloc,
          (s) => s.bootstrapStatus == DetailBootstrapStatus.ready,
        );

        bloc.add(
          UpdateEsportMatch(_match(id: 'M1', homeScore: 1, awayScore: 0)),
        );
        await _waitForState(bloc, (s) => s.pendingMatchIds.contains('M1'));
        expect(toasts, isEmpty);
        bloc.add(
          UpdateEsportMatch(_match(id: 'M2', homeScore: 2, awayScore: 1)),
        );
        await _flush();
        expect(bloc.state.pendingMatchIds, {'M1'});
        expect(toasts, [appText.tournamentMatchUpdated]);
        verify(() => repo.updateMatchAtomically(any())).called(2);
        expect(
          bloc.state.matches.where((m) => m.id == 'M1').single.homeScore,
          isNull,
        );

        m1Write.complete();
        await _waitForState(bloc, (s) => s.pendingMatchIds.isEmpty);
        expect(toasts, [
          appText.tournamentMatchUpdated,
          appText.tournamentMatchUpdated,
        ]);
        verifyNoExplicitDetailReads();
      },
    );

    test(
      'generic failure clears only its pending ID, preserves confirmed row, and permits retry',
      () async {
        final streams = _LeagueStreams();
        addTearDown(streams.close);
        _stubStreams(repo, streams, 'L1');
        var attempts = 0;
        final m2Write = Completer<void>();
        when(() => repo.updateMatchAtomically(any())).thenAnswer((
          invocation,
        ) async {
          final match = invocation.positionalArguments.single as GNEsportMatch;
          if (match.id == 'M2') {
            await m2Write.future;
            return;
          }
          attempts++;
          if (attempts == 1) throw Exception('offline');
        });
        final bloc = build();
        addTearDown(bloc.close);
        bloc.add(const OpenLeagueDetail('L1'));
        await _flush();
        streams.league.add(_league());
        streams.stats.add([]);
        streams.matches.add([
          _match(id: 'M1', homeScore: 0, awayScore: 0),
          _match(id: 'M2', homeScore: 0, awayScore: 0),
        ]);
        await _waitForState(
          bloc,
          (s) => s.bootstrapStatus == DetailBootstrapStatus.ready,
        );

        bloc.add(
          UpdateEsportMatch(_match(id: 'M2', homeScore: 1, awayScore: 0)),
        );
        await _waitForState(bloc, (s) => s.pendingMatchIds.contains('M2'));
        bloc.add(
          UpdateEsportMatch(_match(id: 'M1', homeScore: 5, awayScore: 0)),
        );
        await _waitForState(bloc, (s) => s.matchErrorsById.containsKey('M1'));
        expect(bloc.state.pendingMatchIds, {'M2'});
        expect(bloc.state.matches.firstWhere((m) => m.id == 'M1').homeScore, 0);
        expect(bloc.state.matchErrorsById['M1'], isNotEmpty);

        bloc.add(
          UpdateEsportMatch(_match(id: 'M1', homeScore: 1, awayScore: 0)),
        );
        await _waitForState(
          bloc,
          (s) =>
              s.pendingMatchIds.contains('M2') &&
              !s.pendingMatchIds.contains('M1') &&
              !s.matchErrorsById.containsKey('M1'),
        );
        expect(attempts, 2);
        expect(bloc.state.matches.firstWhere((m) => m.id == 'M1').homeScore, 0);
        m2Write.complete();
        await _waitForState(bloc, (s) => s.pendingMatchIds.isEmpty);
      },
    );

    test(
      'concurrent conflict is per-match and later stream snapshot reconciles server row',
      () async {
        final streams = _LeagueStreams();
        addTearDown(streams.close);
        _stubStreams(repo, streams, 'L1');
        when(
          () => repo.updateMatchAtomically(any()),
        ).thenThrow(ConcurrentMatchUpdateException('M1'));
        final bloc = build();
        addTearDown(bloc.close);
        bloc.add(const OpenLeagueDetail('L1'));
        await _flush();
        streams.league.add(_league());
        streams.stats.add([]);
        streams.matches.add([_match(id: 'M1', homeScore: 0, awayScore: 0)]);
        await _waitForState(
          bloc,
          (s) => s.bootstrapStatus == DetailBootstrapStatus.ready,
        );

        bloc.add(
          UpdateEsportMatch(_match(id: 'M1', homeScore: 9, awayScore: 0)),
        );
        await _waitForState(bloc, (s) => s.matchErrorsById.containsKey('M1'));
        expect(bloc.state.pendingMatchIds, isEmpty);
        expect(bloc.state.matches.single.homeScore, 0);
        expect(
          bloc.state.matchErrorsById['M1'],
          appText.tournamentMatchConcurrentUpdate,
        );
        expect(toasts, [appText.tournamentMatchConcurrentUpdate]);

        streams.matches.add([
          _match(id: 'M1', homeScore: 2, awayScore: 1, isFinished: true),
        ]);
        await _waitForState(bloc, (s) => s.matches.single.homeScore == 2);
        expect(bloc.state.viewStatus, isNot(ViewStatus.loading));
        expect(toasts, [appText.tournamentMatchConcurrentUpdate]);
      },
    );

    test(
      'second bloc receives shared match and stat snapshots without remote toast or loading',
      () async {
        final streams = _LeagueStreams();
        addTearDown(streams.close);
        _stubStreams(repo, streams, 'L1');
        when(() => repo.updateMatchAtomically(any())).thenAnswer((_) async {});
        final blocA = build();
        final blocB = build();
        addTearDown(blocA.close);
        addTearDown(blocB.close);
        blocA.add(const OpenLeagueDetail('L1'));
        blocB.add(const OpenLeagueDetail('L1'));
        await _flush();
        streams.league.add(_league());
        streams.stats.add([_stat('A'), _stat('B')]);
        streams.matches.add([_match(id: 'M1', homeScore: 0, awayScore: 0)]);
        await Future.wait([
          _waitForState(
            blocA,
            (s) => s.bootstrapStatus == DetailBootstrapStatus.ready,
          ),
          _waitForState(
            blocB,
            (s) => s.bootstrapStatus == DetailBootstrapStatus.ready,
          ),
        ]);
        toasts.clear();

        blocA.add(
          UpdateEsportMatch(_match(id: 'M1', homeScore: 2, awayScore: 0)),
        );
        await _waitForState(blocA, (s) => s.pendingMatchIds.contains('M1'));
        await _waitForState(blocA, (s) => !s.pendingMatchIds.contains('M1'));
        streams.matches.add([
          _match(id: 'M1', homeScore: 2, awayScore: 0, isFinished: true),
        ]);
        streams.stats.add([
          _stat('A', wins: 1, goals: 2),
          _stat('B', losses: 1, goalsConceded: 2),
        ]);
        await _waitForState(
          blocB,
          (s) =>
              s.matches.single.homeScore == 2 && s.participants.first.wins == 1,
        );

        expect(blocB.state.viewStatus, isNot(ViewStatus.loading));
        expect(blocB.state.pendingMatchIds, isEmpty);
        expect(toasts, [appText.tournamentMatchUpdated]);
      },
    );
  });

  group('TournamentDetailState stream contract', () {
    test(
      'copyWith defensively freezes maps and sets and supports clear flags',
      () {
        final users = <String, GNUser>{'A': _user('A')};
        final pending = <String>{'M1'};
        final matchErrors = <String, String>{'M1': 'offline'};
        final streamErrors = <TournamentDetailSlice, String>{
          TournamentDetailSlice.stats: 'down',
        };
        final state = const TournamentDetailState().copyWith(
          league: _league(),
          usersById: users,
          pendingMatchIds: pending,
          matchErrorsById: matchErrors,
          streamErrors: streamErrors,
          selectedGroupId: 'G1',
        );
        users['B'] = _user('B');
        pending.add('M2');
        matchErrors['M2'] = 'x';
        streamErrors[TournamentDetailSlice.matches] = 'x';

        expect(state.usersById.keys, ['A']);
        expect(state.pendingMatchIds, {'M1'});
        expect(state.matchErrorsById.keys, ['M1']);
        expect(state.streamErrors.keys, [TournamentDetailSlice.stats]);
        expect(() => state.usersById['C'] = _user('C'), throwsUnsupportedError);
        expect(() => state.pendingMatchIds.add('M3'), throwsUnsupportedError);
        final cleared = state.copyWith(
          clearLeague: true,
          clearSelectedGroupId: true,
        );
        expect(cleared.league, isNull);
        expect(cleared.selectedGroupId, isNull);
      },
    );

    test('bootstrap status is derived from slice outcomes and deletion', () {
      const initial = TournamentDetailState();
      expect(initial.bootstrapStatus, DetailBootstrapStatus.loading);
      final ready = initial.copyWith(
        league: _league(),
        leagueSliceStatus: DetailSliceStatus.ready,
        statsSliceStatus: DetailSliceStatus.failed,
        matchesSliceStatus: DetailSliceStatus.ready,
      );
      expect(ready.bootstrapStatus, DetailBootstrapStatus.ready);
      expect(
        ready.copyWith(leagueDeleted: true).bootstrapStatus,
        DetailBootstrapStatus.failure,
      );
      expect(
        ready
            .copyWith(
              clearLeague: true,
              leagueSliceStatus: DetailSliceStatus.failed,
            )
            .bootstrapStatus,
        DetailBootstrapStatus.failure,
      );
    });
  });

  group('UpdateLeagueCostConfig', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không làm gì khi state.league == null',
      build: build,
      act: (bloc) => bloc.add(
        const UpdateLeagueCostConfig(
          rankPayoutEnabled: true,
          rankPayouts: [50000],
          defaultMatchCost: 50000,
          defaultPerGoalEnabled: false,
          defaultCostPerGoal: 0,
        ),
      ),
      expect: () => const <TournamentDetailState>[],
      verify: (_) => verifyNever(() => repo.updateLeague(any())),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'gọi updateLeague với copyWith đầy đủ field cost mới + emit success',
      build: () {
        when(() => repo.updateLeague(any())).thenAnswer((_) async {});
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(
        const UpdateLeagueCostConfig(
          rankPayoutEnabled: true,
          rankPayouts: [50000, 100000],
          defaultMatchCost: 80000,
          defaultPerGoalEnabled: true,
          defaultCostPerGoal: 70000,
        ),
      ),
      expect: () => [
        // emit loading
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'loading',
          ViewStatus.loading,
        ),
        // emit success với league mới
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'success', ViewStatus.success)
            .having(
              (s) => s.league?.rankPayoutEnabled,
              'rankPayoutEnabled',
              true,
            )
            .having((s) => s.league?.rankPayouts, 'rankPayouts', [
              50000,
              100000,
            ])
            .having(
              (s) => s.league?.defaultMatchCost,
              'defaultMatchCost',
              80000,
            )
            .having(
              (s) => s.league?.defaultPerGoalEnabled,
              'defaultPerGoalEnabled',
              true,
            )
            .having(
              (s) => s.league?.defaultCostPerGoal,
              'defaultCostPerGoal',
              70000,
            ),
      ],
      verify: (_) {
        final captured = verify(() => repo.updateLeague(captureAny())).captured;
        expect(captured, hasLength(1));
        final passed = captured.single as GNEsportLeague;
        expect(passed.rankPayoutEnabled, isTrue);
        expect(passed.rankPayouts, [50000, 100000]);
        expect(passed.defaultMatchCost, 80000);
        expect(passed.defaultPerGoalEnabled, isTrue);
        expect(passed.defaultCostPerGoal, 70000);
        expect(toasts, contains('Đã cập nhật chi phí giải đấu'));
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'emit failure khi repo throw',
      build: () {
        when(() => repo.updateLeague(any())).thenThrow(Exception('boom'));
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(
        const UpdateLeagueCostConfig(
          rankPayoutEnabled: false,
          rankPayouts: [],
          defaultMatchCost: 50000,
          defaultPerGoalEnabled: false,
          defaultCostPerGoal: 0,
        ),
      ),
      expect: () => [
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'loading',
          ViewStatus.loading,
        ),
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'failure', ViewStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', contains('boom')),
      ],
    );
  });

  group('ChangeLeagueStatus', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'cập nhật state.league.status local (không gọi repo)',
      build: () => buildWithLeague(_league(status: 'ongoing')),
      act: (bloc) =>
          bloc.add(const ChangeLeagueStatus(GNEsportLeagueStatus.finished)),
      expect: () => [
        isA<TournamentDetailState>().having(
          (s) => s.league?.status,
          'status',
          GNEsportLeagueStatus.finished.value,
        ),
      ],
      verify: (_) => verifyNever(() => repo.updateLeague(any())),
    );
  });

  group('SubmitLeagueStatus', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không làm gì khi state.league == null',
      build: build,
      act: (bloc) => bloc.add(SubmitLeagueStatus()),
      expect: () => const <TournamentDetailState>[],
      verify: (_) => verifyNever(() => repo.updateLeague(any())),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'gọi repo.updateLeague + toast thành công',
      build: () {
        when(() => repo.updateLeague(any())).thenAnswer((_) async {});
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(SubmitLeagueStatus()),
      expect: () => [
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'loading',
          ViewStatus.loading,
        ),
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'success',
          ViewStatus.success,
        ),
      ],
      verify: (_) {
        verify(() => repo.updateLeague(any())).called(1);
        expect(toasts.any((t) => t.contains('trạng thái')), isTrue);
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'repo throw: emit failure',
      build: () {
        when(() => repo.updateLeague(any())).thenThrow(Exception('x'));
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(SubmitLeagueStatus()),
      expect: () => [
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'loading',
          ViewStatus.loading,
        ),
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'failure',
          ViewStatus.failure,
        ),
      ],
    );
  });

  group('InactiveLeague', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không làm gì khi không có league',
      build: build,
      act: (bloc) => bloc.add(InactiveLeague()),
      expect: () => const <TournamentDetailState>[],
      verify: (_) => verifyNever(() => repo.inactiveLeague(any())),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'gọi inactiveLeague + toast',
      build: () {
        when(() => repo.inactiveLeague(any())).thenAnswer((_) async {});
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(InactiveLeague()),
      expect: () => [
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'loading',
          ViewStatus.loading,
        ),
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'success',
          ViewStatus.success,
        ),
      ],
      verify: (_) {
        verify(() => repo.inactiveLeague(any())).called(1);
        expect(toasts.any((t) => t.contains('Đã xoá')), isTrue);
      },
    );
  });

  group('GenerateRound', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không làm gì khi participants < 2',
      build: () {
        final bloc = buildWithLeague(_league());
        bloc.emit(bloc.state.copyWith(participants: [_stat('A')]));
        return bloc;
      },
      act: (bloc) => bloc.add(const GenerateRound()),
      expect: () => const <TournamentDetailState>[],
      verify: (_) => verifyNever(
        () => repo.generateRound(
          leagueId: any(named: 'leagueId'),
          teamIds: any(named: 'teamIds'),
        ),
      ),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'gọi generateRound với danh sách userIds + toast',
      build: () {
        when(
          () => repo.generateRound(
            leagueId: any(named: 'leagueId'),
            teamIds: any(named: 'teamIds'),
          ),
        ).thenAnswer((_) async {});
        when(() => repo.getMatches(any())).thenAnswer((_) async => []);
        final bloc = buildWithLeague(_league());
        bloc.emit(
          bloc.state.copyWith(
            participants: [_stat('A'), _stat('B'), _stat('C')],
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const GenerateRound()),
      verify: (_) {
        final captured = verify(
          () => repo.generateRound(
            leagueId: 'L1',
            teamIds: captureAny(named: 'teamIds'),
          ),
        ).captured;
        expect(captured.single, ['A', 'B', 'C']);
        expect(toasts.any((t) => t.contains('Tạo lượt đấu')), isTrue);
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'RoundTooLargeException hiện toast đã dịch thay vì e.toString()',
      build: () {
        when(
          () => repo.generateRound(
            leagueId: any(named: 'leagueId'),
            teamIds: any(named: 'teamIds'),
          ),
        ).thenThrow(
          RoundTooLargeException(participantCount: 33, maxParticipants: 32),
        );
        final bloc = buildWithLeague(_league());
        bloc.emit(bloc.state.copyWith(participants: [_stat('A'), _stat('B')]));
        return bloc;
      },
      act: (bloc) => bloc.add(const GenerateRound()),
      verify: (bloc) {
        expect(toasts.any((t) => t.contains('32')), isTrue);
        expect(
          toasts.any((t) => t.contains('RoundTooLargeException')),
          isFalse,
        );
        expect(bloc.state.viewStatus, isNot(ViewStatus.loading));
        expect(bloc.state.errorMessage, isNot(contains('RoundTooLarge')));
      },
    );
  });

  group('TournamentDetailState computed', () {
    test('fixtures = matches chưa finished', () {
      const state = TournamentDetailState();
      final s = state.copyWith(
        matches: [
          _match(id: 'm1', isFinished: false),
          _match(id: 'm2', isFinished: true),
        ],
      );
      expect(s.fixtures.map((e) => e.id), ['m1']);
    });

    test('fixtures loại bỏ match có phase=knockout', () {
      const state = TournamentDetailState();
      final s = state.copyWith(
        matches: [
          _match(id: 'm1', isFinished: false),
          _match(id: 'ko1', isFinished: false, phase: 'knockout'),
          _match(
            id: 'ko2',
            isFinished: false,
            home: 'A1',
            away: 'B1',
            phase: 'knockout',
          ),
        ],
      );
      expect(s.fixtures.map((e) => e.id), ['m1']);
    });

    test('results = matches đã finished', () {
      const state = TournamentDetailState();
      final s = state.copyWith(
        matches: [
          _match(id: 'm1', isFinished: false),
          _match(id: 'm2', isFinished: true),
        ],
      );
      expect(s.results.map((e) => e.id), ['m2']);
    });

    test('copyWith giữ nguyên selectedGroupId khi không truyền tham số', () {
      const state = TournamentDetailState(selectedGroupId: 'A');
      expect(state.copyWith().selectedGroupId, 'A');
    });

    test(
      'copyWith(clearSelectedGroupId: true) xoá selectedGroupId về null',
      () {
        const state = TournamentDetailState(selectedGroupId: 'A');
        expect(
          state.copyWith(clearSelectedGroupId: true).selectedGroupId,
          isNull,
        );
      },
    );

    test('copyWith(selectedGroupId: "B") cập nhật selectedGroupId', () {
      const state = TournamentDetailState(selectedGroupId: 'A');
      expect(state.copyWith(selectedGroupId: 'B').selectedGroupId, 'B');
    });
  });

  group('SelectGroup', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'SelectGroup với groupId → emit state có selectedGroupId',
      build: build,
      act: (bloc) => bloc.add(const SelectGroup('A')),
      expect: () => [
        isA<TournamentDetailState>().having(
          (s) => s.selectedGroupId,
          'selectedGroupId',
          'A',
        ),
      ],
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'SelectGroup(null) → emit state với selectedGroupId = null',
      build: () {
        final b = build();
        b.emit(b.state.copyWith(selectedGroupId: 'A'));
        return b;
      },
      act: (bloc) => bloc.add(const SelectGroup(null)),
      expect: () => [
        isA<TournamentDetailState>().having(
          (s) => s.selectedGroupId,
          'selectedGroupId',
          isNull,
        ),
      ],
    );
  });

  // ---------- handlers còn lại ----------

  group('CreateCustomMatch', () {
    final user1 = const GNUser(
      id: 'A',
      email: null,
      displayName: 'A',
      photoUrl: null,
      phoneNumber: null,
      role: 'user',
    );
    final user2 = const GNUser(
      id: 'B',
      email: null,
      displayName: 'B',
      photoUrl: null,
      phoneNumber: null,
      role: 'user',
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'state đang loading ⇒ no-op',
      build: () {
        final bloc = buildWithLeague(_league());
        bloc.emit(bloc.state.copyWith(viewStatus: ViewStatus.loading));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(CreateCustomMatch(homeTeam: user1, awayTeam: user2)),
      verify: (_) => verifyNever(() => repo.createCustomMatch(any())),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không có league ⇒ no-op',
      build: build,
      act: (bloc) =>
          bloc.add(CreateCustomMatch(homeTeam: user1, awayTeam: user2)),
      verify: (_) => verifyNever(() => repo.createCustomMatch(any())),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'success: gọi createCustomMatch + toast',
      build: () {
        when(() => repo.createCustomMatch(any())).thenAnswer((_) async {});
        when(() => repo.getMatches(any())).thenAnswer((_) async => []);
        return buildWithLeague(_league());
      },
      act: (bloc) =>
          bloc.add(CreateCustomMatch(homeTeam: user1, awayTeam: user2)),
      verify: (_) {
        final captured = verify(
          () => repo.createCustomMatch(captureAny()),
        ).captured;
        final m = captured.single as GNEsportMatch;
        expect(m.homeTeamId, 'A');
        expect(m.awayTeamId, 'B');
        expect(m.leagueId, 'L1');
        expect(m.isFinished, isFalse);
        expect(toasts.any((t) => t.contains('Tạo trận')), isTrue);
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'failure: emit failure',
      build: () {
        when(() => repo.createCustomMatch(any())).thenThrow(Exception('x'));
        return buildWithLeague(_league());
      },
      act: (bloc) =>
          bloc.add(CreateCustomMatch(homeTeam: user1, awayTeam: user2)),
      expect: () => [
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'loading',
          ViewStatus.loading,
        ),
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'failure',
          ViewStatus.failure,
        ),
      ],
    );
  });

  group('DeleteEsportMatch', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không league ⇒ no-op',
      build: build,
      act: (bloc) => bloc.add(DeleteEsportMatch(_match())),
      verify: (_) => verifyNever(() => repo.deleteMatch(any())),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'success: gọi deleteMatch, stream tiếp tục sở hữu refresh',
      build: () {
        when(() => repo.deleteMatch(any())).thenAnswer((_) async {});
        when(() => repo.getLeagueStats(any())).thenAnswer((_) async => []);
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(DeleteEsportMatch(_match())),
      verify: (_) {
        verify(() => repo.deleteMatch(any())).called(1);
        expect(toasts.any((t) => t.contains('Xoá trận')), isTrue);
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'failure: emit failure',
      build: () {
        when(() => repo.deleteMatch(any())).thenThrow(Exception('x'));
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(DeleteEsportMatch(_match())),
      expect: () => [
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'loading',
          ViewStatus.loading,
        ),
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'failure',
          ViewStatus.failure,
        ),
      ],
    );
  });

  group('AddParticipant', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không league ⇒ no-op',
      build: build,
      act: (bloc) => bloc.add(const AddParticipant('L1', 'U1')),
      verify: (_) => verifyNever(
        () => repo.addParticipant(
          leagueId: any(named: 'leagueId'),
          userId: any(named: 'userId'),
        ),
      ),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'success: thêm + toast + load lại stats',
      build: () {
        when(
          () => repo.addParticipant(
            leagueId: any(named: 'leagueId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async {});
        when(() => repo.getLeagueStats(any())).thenAnswer((_) async => []);
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(const AddParticipant('L1', 'U1')),
      verify: (_) {
        verify(
          () => repo.addParticipant(leagueId: 'L1', userId: 'U1'),
        ).called(1);
        expect(toasts.any((t) => t.contains('Thêm người chơi')), isTrue);
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'failure: emit failure',
      build: () {
        when(
          () => repo.addParticipant(
            leagueId: any(named: 'leagueId'),
            userId: any(named: 'userId'),
          ),
        ).thenThrow(Exception('x'));
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(const AddParticipant('L1', 'U1')),
      expect: () => [
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'loading',
          ViewStatus.loading,
        ),
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'failure',
          ViewStatus.failure,
        ),
      ],
    );
  });

  group('AddMultipleParticipants', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không league ⇒ no-op',
      build: build,
      act: (bloc) =>
          bloc.add(const AddMultipleParticipants('L1', ['U1', 'U2'])),
      verify: (_) => verifyNever(
        () => repo.addMultipleParticipants(
          leagueId: any(named: 'leagueId'),
          userIds: any(named: 'userIds'),
        ),
      ),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'userIds rỗng ⇒ no-op',
      build: () => buildWithLeague(_league()),
      act: (bloc) => bloc.add(const AddMultipleParticipants('L1', [])),
      verify: (_) => verifyNever(
        () => repo.addMultipleParticipants(
          leagueId: any(named: 'leagueId'),
          userIds: any(named: 'userIds'),
        ),
      ),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'success',
      build: () {
        when(
          () => repo.addMultipleParticipants(
            leagueId: any(named: 'leagueId'),
            userIds: any(named: 'userIds'),
          ),
        ).thenAnswer((_) async {});
        when(() => repo.getLeagueStats(any())).thenAnswer((_) async => []);
        return buildWithLeague(_league());
      },
      act: (bloc) =>
          bloc.add(const AddMultipleParticipants('L1', ['U1', 'U2'])),
      verify: (_) {
        verify(
          () => repo.addMultipleParticipants(
            leagueId: 'L1',
            userIds: ['U1', 'U2'],
          ),
        ).called(1);
        expect(toasts.any((t) => t.contains('2 người chơi')), isTrue);
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'failure: emit failure',
      build: () {
        when(
          () => repo.addMultipleParticipants(
            leagueId: any(named: 'leagueId'),
            userIds: any(named: 'userIds'),
          ),
        ).thenThrow(Exception('x'));
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(const AddMultipleParticipants('L1', ['U1'])),
      expect: () => [
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'loading',
          ViewStatus.loading,
        ),
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'failure',
          ViewStatus.failure,
        ),
      ],
    );
  });

  group('GenerateRound failure path', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không league ⇒ no-op',
      build: build,
      act: (bloc) => bloc.add(const GenerateRound()),
      verify: (_) => verifyNever(
        () => repo.generateRound(
          leagueId: any(named: 'leagueId'),
          teamIds: any(named: 'teamIds'),
        ),
      ),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'state loading ⇒ no-op',
      build: () {
        final bloc = buildWithLeague(_league());
        bloc.emit(
          bloc.state.copyWith(
            participants: [_stat('A'), _stat('B')],
            viewStatus: ViewStatus.loading,
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const GenerateRound()),
      verify: (_) => verifyNever(
        () => repo.generateRound(
          leagueId: any(named: 'leagueId'),
          teamIds: any(named: 'teamIds'),
        ),
      ),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'repo throw: emit failure',
      build: () {
        when(
          () => repo.generateRound(
            leagueId: any(named: 'leagueId'),
            teamIds: any(named: 'teamIds'),
          ),
        ).thenThrow(Exception('x'));
        final bloc = buildWithLeague(_league());
        bloc.emit(bloc.state.copyWith(participants: [_stat('A'), _stat('B')]));
        return bloc;
      },
      act: (bloc) => bloc.add(const GenerateRound()),
      expect: () => [
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'loading',
          ViewStatus.loading,
        ),
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'failure',
          ViewStatus.failure,
        ),
      ],
    );
  });

  group('InactiveLeague failure path', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'repo throw: emit failure',
      build: () {
        when(() => repo.inactiveLeague(any())).thenThrow(Exception('x'));
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(InactiveLeague()),
      expect: () => [
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'loading',
          ViewStatus.loading,
        ),
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'failure',
          ViewStatus.failure,
        ),
      ],
    );
  });

  group('GenerateGroupRound', () {
    GNEsportLeagueStat statWithGroup(String userId, String groupId) =>
        GNEsportLeagueStat(
          id: 'S_$userId',
          userId: userId,
          leagueId: 'L1',
          matchesPlayed: 0,
          goals: 0,
          goalsConceded: 0,
          wins: 0,
          draws: 0,
          losses: 0,
          groupId: groupId,
        );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không làm gì khi league null',
      build: build,
      act: (bloc) => bloc.add(const GenerateGroupRound('G1')),
      expect: () => const <TournamentDetailState>[],
      verify: (_) => verifyNever(
        () => repo.generateGroupRound(
          leagueId: any(named: 'leagueId'),
          groupId: any(named: 'groupId'),
          teamIds: any(named: 'teamIds'),
        ),
      ),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không làm gì khi nhóm có < 2 thành viên',
      build: () {
        final bloc = build();
        bloc.emit(
          bloc.state.copyWith(
            league: _league(),
            participants: [statWithGroup('U1', 'G1')],
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const GenerateGroupRound('G1')),
      expect: () => const <TournamentDetailState>[],
      verify: (_) => verifyNever(
        () => repo.generateGroupRound(
          leagueId: any(named: 'leagueId'),
          groupId: any(named: 'groupId'),
          teamIds: any(named: 'teamIds'),
        ),
      ),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'thành công → gọi generateGroupRound',
      build: () {
        when(
          () => repo.generateGroupRound(
            leagueId: any(named: 'leagueId'),
            groupId: any(named: 'groupId'),
            teamIds: any(named: 'teamIds'),
          ),
        ).thenAnswer((_) async {});
        final bloc = build();
        bloc.emit(
          bloc.state.copyWith(
            league: _league(),
            participants: [
              statWithGroup('U1', 'G1'),
              statWithGroup('U2', 'G1'),
            ],
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const GenerateGroupRound('G1')),
      verify: (_) {
        verify(
          () => repo.generateGroupRound(
            leagueId: 'L1',
            groupId: 'G1',
            teamIds: any(named: 'teamIds'),
          ),
        ).called(1);
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'repo throw → emit failure',
      build: () {
        when(
          () => repo.generateGroupRound(
            leagueId: any(named: 'leagueId'),
            groupId: any(named: 'groupId'),
            teamIds: any(named: 'teamIds'),
          ),
        ).thenThrow(Exception('boom'));
        final bloc = build();
        bloc.emit(
          bloc.state.copyWith(
            league: _league(),
            participants: [
              statWithGroup('U1', 'G1'),
              statWithGroup('U2', 'G1'),
            ],
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const GenerateGroupRound('G1')),
      expect: () => [
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'loading',
          ViewStatus.loading,
        ),
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'failure', ViewStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', isNotEmpty),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // RecomputeStats
  // ---------------------------------------------------------------------------

  group('RecomputeStats', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không làm gì khi league null',
      build: build,
      act: (bloc) => bloc.add(RecomputeStats()),
      expect: () => const <TournamentDetailState>[],
      verify: (_) => verifyNever(() => repo.recomputeLeagueStats(any())),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'thành công → gọi recomputeLeagueStats',
      build: () {
        when(() => repo.recomputeLeagueStats(any())).thenAnswer((_) async {});
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(RecomputeStats()),
      verify: (_) {
        verify(() => repo.recomputeLeagueStats('L1')).called(1);
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'repo throw → emit failure',
      build: () {
        when(
          () => repo.recomputeLeagueStats(any()),
        ).thenThrow(Exception('network'));
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(RecomputeStats()),
      expect: () => [
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'loading',
          ViewStatus.loading,
        ),
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'failure',
          ViewStatus.failure,
        ),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // GenerateCup
  // ---------------------------------------------------------------------------

  group('GenerateCup', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không làm gì khi league null',
      build: build,
      act: (bloc) => bloc.add(const GenerateCup(['U1', 'U2'])),
      expect: () => const <TournamentDetailState>[],
      verify: (_) => verifyNever(
        () => repo.generateCupBracket(
          leagueId: any(named: 'leagueId'),
          seededTeamIds: any(named: 'seededTeamIds'),
        ),
      ),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'thành công → gọi generateCupBracket',
      build: () {
        when(
          () => repo.generateCupBracket(
            leagueId: any(named: 'leagueId'),
            seededTeamIds: any(named: 'seededTeamIds'),
          ),
        ).thenAnswer((_) async {});
        when(() => repo.getMatches(any())).thenAnswer((_) async => const []);
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(const GenerateCup(['U1', 'U2'])),
      verify: (_) {
        verify(
          () => repo.generateCupBracket(
            leagueId: 'L1',
            seededTeamIds: ['U1', 'U2'],
          ),
        ).called(1);
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'repo throw → emit failure',
      build: () {
        when(
          () => repo.generateCupBracket(
            leagueId: any(named: 'leagueId'),
            seededTeamIds: any(named: 'seededTeamIds'),
          ),
        ).thenThrow(Exception('boom'));
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(const GenerateCup([])),
      expect: () => [
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'loading',
          ViewStatus.loading,
        ),
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'failure',
          ViewStatus.failure,
        ),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // GenerateFull
  // ---------------------------------------------------------------------------

  group('GenerateFull', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không làm gì khi league null',
      build: build,
      act: (bloc) => bloc.add(
        const GenerateFull(
          groups: [
            ['U1'],
          ],
          advanceCount: 1,
        ),
      ),
      expect: () => const <TournamentDetailState>[],
      verify: (_) => verifyNever(
        () => repo.generateFullTournament(
          leagueId: any(named: 'leagueId'),
          groups: any(named: 'groups'),
          advanceCount: any(named: 'advanceCount'),
        ),
      ),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'thành công → gọi generateFullTournament',
      build: () {
        when(
          () => repo.generateFullTournament(
            leagueId: any(named: 'leagueId'),
            groups: any(named: 'groups'),
            advanceCount: any(named: 'advanceCount'),
          ),
        ).thenAnswer((_) async {});
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(
        const GenerateFull(
          groups: [
            ['U1', 'U2'],
            ['U3', 'U4'],
          ],
          advanceCount: 2,
        ),
      ),
      verify: (_) {
        verify(
          () => repo.generateFullTournament(
            leagueId: 'L1',
            groups: [
              ['U1', 'U2'],
              ['U3', 'U4'],
            ],
            advanceCount: 2,
          ),
        ).called(1);
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'repo throw → emit failure',
      build: () {
        when(
          () => repo.generateFullTournament(
            leagueId: any(named: 'leagueId'),
            groups: any(named: 'groups'),
            advanceCount: any(named: 'advanceCount'),
          ),
        ).thenThrow(Exception('boom'));
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(
        const GenerateFull(
          groups: [
            ['U1', 'U2'],
          ],
          advanceCount: 1,
        ),
      ),
      expect: () => [
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'loading',
          ViewStatus.loading,
        ),
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'failure',
          ViewStatus.failure,
        ),
      ],
    );
  });
}
