import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart';

class _MockRepo extends Mock implements EsportLeagueRepository {}

class _FakeMatch extends Fake implements GNEsportMatch {}

class _FakeLeague extends Fake implements GNEsportLeague {}

GNEsportLeague _league({
  String id = 'L1',
  String? status,
  bool rankPayoutEnabled = false,
  List<int> rankPayouts = const [],
  int defaultMatchCost = 50000,
  bool isActive = true,
}) {
  return GNEsportLeague(
    id: id,
    ownerId: 'owner',
    groupId: 'G1',
    name: 'L',
    startDate: DateTime(2026, 1, 1),
    isActive: isActive,
    description: '',
    participants: const [],
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
  bool isFinished = false,
  int? homeScore,
  int? awayScore,
}) {
  return GNEsportMatch(
    id: id,
    homeTeamId: home,
    awayTeamId: away,
    homeScore: homeScore,
    awayScore: awayScore,
    date: DateTime(2026, 1, 1),
    isFinished: isFinished,
    leagueId: 'L1',
  );
}

GNEsportLeagueStat _stat(
  String userId, {
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
    leagueId: 'L1',
    matchesPlayed: wins + draws + losses,
    goals: goals,
    goalsConceded: goalsConceded,
    wins: wins,
    draws: draws,
    losses: losses,
    user: user,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeMatch());
    registerFallbackValue(_FakeLeague());
  });

  late _MockRepo repo;
  late List<String> toasts;

  setUp(() {
    repo = _MockRepo();
    toasts = [];
    setShowToastImpl((msg, {gravity = ToastGravity.BOTTOM}) =>
        toasts.add(msg));

    // Streams thường được listen ở init flows — stub bằng empty stream để
    // các handler nào subscribe không crash.
    when(() => repo.listenForLeagueStats(any()))
        .thenAnswer((_) => const Stream.empty());
    when(() => repo.listenForMatchesUpdated(any()))
        .thenAnswer((_) => const Stream.empty());
    when(() => repo.listenForLeagueUpdated(any()))
        .thenAnswer((_) => const Stream.empty());
  });

  tearDown(() {
    resetShowToast();
  });

  TournamentDetailBloc build() => TournamentDetailBloc(repo);

  TournamentDetailBloc buildWithLeague(GNEsportLeague league) {
    final bloc = TournamentDetailBloc(repo);
    bloc.emit(bloc.state.copyWith(league: league));
    return bloc;
  }

  group('UpdateLeagueCostConfig', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không làm gì khi state.league == null',
      build: build,
      act: (bloc) => bloc.add(const UpdateLeagueCostConfig(
        rankPayoutEnabled: true,
        rankPayouts: [50000],
        defaultMatchCost: 50000,
      )),
      expect: () => const <TournamentDetailState>[],
      verify: (_) => verifyNever(() => repo.updateLeague(any())),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'gọi updateLeague với copyWith đầy đủ field cost mới + emit success',
      build: () {
        when(() => repo.updateLeague(any())).thenAnswer((_) async {});
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(const UpdateLeagueCostConfig(
        rankPayoutEnabled: true,
        rankPayouts: [50000, 100000],
        defaultMatchCost: 80000,
      )),
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
            .having((s) => s.league?.rankPayoutEnabled, 'rankPayoutEnabled', true)
            .having((s) => s.league?.rankPayouts, 'rankPayouts',
                [50000, 100000])
            .having(
              (s) => s.league?.defaultMatchCost,
              'defaultMatchCost',
              80000,
            ),
      ],
      verify: (_) {
        final captured =
            verify(() => repo.updateLeague(captureAny())).captured;
        expect(captured, hasLength(1));
        final passed = captured.single as GNEsportLeague;
        expect(passed.rankPayoutEnabled, isTrue);
        expect(passed.rankPayouts, [50000, 100000]);
        expect(passed.defaultMatchCost, 80000);
        expect(toasts, contains('Đã cập nhật chi phí giải đấu'));
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'emit failure khi repo throw',
      build: () {
        when(() => repo.updateLeague(any()))
            .thenThrow(Exception('boom'));
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(const UpdateLeagueCostConfig(
        rankPayoutEnabled: false,
        rankPayouts: [],
        defaultMatchCost: 50000,
      )),
      expect: () => [
        isA<TournamentDetailState>().having(
          (s) => s.viewStatus,
          'loading',
          ViewStatus.loading,
        ),
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'failure', ViewStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage',
                contains('boom')),
      ],
    );
  });

  group('GetLeague', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'success: emit league sau khi load',
      build: () {
        when(() => repo.getLeague('L1'))
            .thenAnswer((_) async => _league(id: 'L1'));
        return build();
      },
      act: (bloc) => bloc.add(const GetLeague('L1')),
      skip: 1, // bỏ qua emit loading
      expect: () => [
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'success', ViewStatus.success)
            .having((s) => s.league?.id, 'league.id', 'L1'),
      ],
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không tìm thấy league: emit failure',
      build: () {
        when(() => repo.getLeague(any())).thenAnswer((_) async => null);
        return build();
      },
      act: (bloc) => bloc.add(const GetLeague('missing')),
      skip: 1,
      expect: () => [
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'failure', ViewStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage',
                'Không tìm thấy giải đấu'),
      ],
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'repo throw: emit failure',
      build: () {
        when(() => repo.getLeague(any())).thenThrow(Exception('net'));
        return build();
      },
      act: (bloc) => bloc.add(const GetLeague('L1')),
      skip: 1,
      expect: () => [
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'failure', ViewStatus.failure),
      ],
    );
  });

  group('UpdateMatches', () {
    test('mỗi match copyWith user từ state.users', () async {
      const user1 = GNUser(
        id: 'A',
        email: 'a@test',
        displayName: 'Alice',
        photoUrl: null,
        phoneNumber: null,
        role: 'user',
        fcmToken: '',
      );
      const user2 = GNUser(
        id: 'B',
        email: 'b@test',
        displayName: 'Bob',
        photoUrl: null,
        phoneNumber: null,
        role: 'user',
        fcmToken: '',
      );
      final bloc = build();
      bloc.emit(bloc.state.copyWith(users: [user1, user2]));

      bloc.add(UpdateMatches([_match(home: 'A', away: 'B')]));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.matches, hasLength(1));
      expect(bloc.state.matches.first.homeTeam?.id, 'A');
      expect(bloc.state.matches.first.awayTeam?.id, 'B');
    });
  });

  group('ChangeLeagueStatus', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'cập nhật state.league.status local (không gọi repo)',
      build: () => buildWithLeague(_league(status: 'ongoing')),
      act: (bloc) => bloc.add(
        const ChangeLeagueStatus(GNEsportLeagueStatus.finished),
      ),
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
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'loading', ViewStatus.loading),
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'success', ViewStatus.success),
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
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'loading', ViewStatus.loading),
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'failure', ViewStatus.failure),
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
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'loading', ViewStatus.loading),
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'success', ViewStatus.success),
      ],
      verify: (_) {
        verify(() => repo.inactiveLeague(any())).called(1);
        expect(toasts.any((t) => t.contains('Đã xoá')), isTrue);
      },
    );
  });

  group('GetParticipantsAndMatches sort', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'sort participants theo points → goalDifference → goals → matchesPlayed',
      build: () {
        // C: points=6 (2W), gd=+5 → rank 1
        // A: points=6 (2W), gd=+3 → rank 2
        // B: points=3 (1W), gd=+1 → rank 3
        // D: points=0 → rank 4
        final stats = [
          _stat('A', wins: 2, goals: 5, goalsConceded: 2),
          _stat('B', wins: 1, draws: 0, losses: 1, goals: 2, goalsConceded: 1),
          _stat('C', wins: 2, goals: 7, goalsConceded: 2),
          _stat('D', losses: 2, goals: 0, goalsConceded: 4),
        ];
        when(() => repo.getParticipantsAndMatches(any())).thenAnswer(
          (_) async => LeagueDetailData(participants: stats, matches: []),
        );
        return build();
      },
      act: (bloc) =>
          bloc.add(const GetParticipantsAndMatches('L1')),
      skip: 1, // bỏ qua loading
      expect: () => [
        isA<TournamentDetailState>().having(
          (s) => s.participants.map((e) => e.userId).toList(),
          'order',
          ['C', 'A', 'B', 'D'],
        ),
      ],
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'tie-break tiếp theo: goals scored',
      build: () {
        // A và B cùng points=3, cùng goalDifference=1, A goals=4 > B goals=2
        final stats = [
          _stat('B', wins: 1, losses: 1, goals: 2, goalsConceded: 1),
          _stat('A', wins: 1, losses: 1, goals: 4, goalsConceded: 3),
        ];
        when(() => repo.getParticipantsAndMatches(any())).thenAnswer(
          (_) async => LeagueDetailData(participants: stats, matches: []),
        );
        return build();
      },
      act: (bloc) =>
          bloc.add(const GetParticipantsAndMatches('L1')),
      skip: 1,
      expect: () => [
        isA<TournamentDetailState>().having(
          (s) => s.participants.first.userId,
          'first',
          'A',
        ),
      ],
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'repo throw: emit failure',
      build: () {
        when(() => repo.getParticipantsAndMatches(any()))
            .thenThrow(Exception('x'));
        return build();
      },
      act: (bloc) =>
          bloc.add(const GetParticipantsAndMatches('L1')),
      skip: 1,
      expect: () => [
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'failure', ViewStatus.failure),
      ],
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
      verify: (_) =>
          verifyNever(() => repo.generateRound(leagueId: any(named: 'leagueId'), teamIds: any(named: 'teamIds'))),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'gọi generateRound với danh sách userIds + toast',
      build: () {
        when(() => repo.generateRound(
              leagueId: any(named: 'leagueId'),
              teamIds: any(named: 'teamIds'),
            )).thenAnswer((_) async {});
        when(() => repo.getMatches(any())).thenAnswer((_) async => []);
        final bloc = buildWithLeague(_league());
        bloc.emit(bloc.state
            .copyWith(participants: [_stat('A'), _stat('B'), _stat('C')]));
        return bloc;
      },
      act: (bloc) => bloc.add(const GenerateRound()),
      verify: (_) {
        final captured = verify(() => repo.generateRound(
              leagueId: 'L1',
              teamIds: captureAny(named: 'teamIds'),
            )).captured;
        expect(captured.single, ['A', 'B', 'C']);
        expect(toasts.any((t) => t.contains('Tạo vòng đấu')), isTrue);
      },
    );
  });

  group('UpdateEsportMatch', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không làm gì khi không có league',
      build: build,
      act: (bloc) => bloc.add(UpdateEsportMatch(_match())),
      expect: () => const <TournamentDetailState>[],
      verify: (_) => verifyNever(() => repo.updateMatch(any())),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'gọi updateMatch + toast thành công',
      build: () {
        when(() => repo.updateMatch(any())).thenAnswer((_) async {});
        when(() => repo.getLeagueStats(any())).thenAnswer((_) async => []);
        when(() => repo.getMatches(any())).thenAnswer((_) async => []);
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(UpdateEsportMatch(_match(homeScore: 2, awayScore: 1))),
      verify: (_) {
        verify(() => repo.updateMatch(any())).called(1);
        expect(toasts.any((t) => t.contains('Cập nhật trận đấu')), isTrue);
      },
    );
  });

  group('LoadLeagueError', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'emit failure với message',
      build: build,
      act: (bloc) => bloc.add(const LoadLeagueError('oops')),
      expect: () => [
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'failure', ViewStatus.failure)
            .having((s) => s.errorMessage, 'msg', 'oops'),
      ],
    );
  });

  group('TournamentDetailState computed', () {
    test('fixtures = matches chưa finished', () {
      const state = TournamentDetailState();
      final s = state.copyWith(matches: [
        _match(id: 'm1', isFinished: false),
        _match(id: 'm2', isFinished: true),
      ]);
      expect(s.fixtures.map((e) => e.id), ['m1']);
    });

    test('results = matches đã finished', () {
      const state = TournamentDetailState();
      final s = state.copyWith(matches: [
        _match(id: 'm1', isFinished: false),
        _match(id: 'm2', isFinished: true),
      ]);
      expect(s.results.map((e) => e.id), ['m2']);
    });

    test('sumRange tính tổng đúng', () {
      const state = TournamentDetailState();
      expect(state.sumRange(1, 3), 6); // 1+2+3
      expect(state.sumRange(2, 5), 14); // 2+3+4+5
    });
  });

  // ---------- handlers còn lại ----------

  group('UpdateLeague', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'merge group hiện tại + nếu isActive ⇒ add GetParticipantsAndMatches',
      build: () {
        when(() => repo.getParticipantsAndMatches(any())).thenAnswer(
          (_) async => const LeagueDetailData(participants: [], matches: []),
        );
        return build();
      },
      act: (bloc) =>
          bloc.add(UpdateLeague(_league(id: 'L1', isActive: true))),
      verify: (_) {
        verify(() => repo.getParticipantsAndMatches('L1')).called(1);
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'isActive = false ⇒ không gọi getParticipantsAndMatches',
      build: build,
      act: (bloc) =>
          bloc.add(UpdateLeague(_league(id: 'L1', isActive: false))),
      verify: (_) {
        verifyNever(() => repo.getParticipantsAndMatches(any()));
      },
    );
  });

  group('UpdateMatchMedals', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không league ⇒ no-op',
      build: build,
      act: (bloc) => bloc.add(const UpdateMatchMedals('M1', 5)),
      expect: () => const <TournamentDetailState>[],
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'success: gọi repo + add GetMatches',
      build: () {
        when(() => repo.updateMatchMedals(any(), any(), any()))
            .thenAnswer((_) async {});
        when(() => repo.getMatches(any())).thenAnswer((_) async => []);
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(const UpdateMatchMedals('M1', 5)),
      verify: (_) {
        verify(() => repo.updateMatchMedals('M1', 'L1', 5)).called(1);
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'failure: emit failure',
      build: () {
        when(() => repo.updateMatchMedals(any(), any(), any()))
            .thenThrow(Exception('x'));
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(const UpdateMatchMedals('M1', 5)),
      expect: () => [
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'loading', ViewStatus.loading),
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'failure', ViewStatus.failure),
      ],
    );
  });

  group('UpdateStartingMedals', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không league ⇒ no-op',
      build: build,
      act: (bloc) => bloc.add(const UpdateStartingMedals(10)),
      expect: () => const <TournamentDetailState>[],
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'success',
      build: () {
        when(() => repo.updateLeagueStartingMedals(any(), any()))
            .thenAnswer((_) async {});
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(const UpdateStartingMedals(10)),
      verify: (_) =>
          verify(() => repo.updateLeagueStartingMedals('L1', 10)).called(1),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'failure: emit failure',
      build: () {
        when(() => repo.updateLeagueStartingMedals(any(), any()))
            .thenThrow(Exception('x'));
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(const UpdateStartingMedals(10)),
      expect: () => [
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'loading', ViewStatus.loading),
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'failure', ViewStatus.failure),
      ],
    );
  });

  group('UpdateUnitMedals', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không league ⇒ no-op',
      build: build,
      act: (bloc) => bloc.add(const UpdateUnitMedals(2)),
      expect: () => const <TournamentDetailState>[],
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'success: emit success',
      build: () {
        when(() => repo.updateLeagueUnitMedals(any(), any()))
            .thenAnswer((_) async {});
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(const UpdateUnitMedals(2)),
      expect: () => [
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'loading', ViewStatus.loading),
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'success', ViewStatus.success),
      ],
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'failure: emit failure',
      build: () {
        when(() => repo.updateLeagueUnitMedals(any(), any()))
            .thenThrow(Exception('x'));
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(const UpdateUnitMedals(2)),
      expect: () => [
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'loading', ViewStatus.loading),
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'failure', ViewStatus.failure),
      ],
    );
  });

  group('CreateCustomMatch', () {
    final user1 = const GNUser(
      id: 'A',
      email: null,
      displayName: 'A',
      photoUrl: null,
      phoneNumber: null,
      role: 'user',
      fcmToken: '',
    );
    final user2 = const GNUser(
      id: 'B',
      email: null,
      displayName: 'B',
      photoUrl: null,
      phoneNumber: null,
      role: 'user',
      fcmToken: '',
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'state đang loading ⇒ no-op',
      build: () {
        final bloc = buildWithLeague(_league());
        bloc.emit(bloc.state.copyWith(viewStatus: ViewStatus.loading));
        return bloc;
      },
      act: (bloc) => bloc.add(CreateCustomMatch(homeTeam: user1, awayTeam: user2)),
      verify: (_) => verifyNever(() => repo.createCustomMatch(any())),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không có league ⇒ no-op',
      build: build,
      act: (bloc) => bloc.add(CreateCustomMatch(homeTeam: user1, awayTeam: user2)),
      verify: (_) => verifyNever(() => repo.createCustomMatch(any())),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'success: gọi createCustomMatch + toast',
      build: () {
        when(() => repo.createCustomMatch(any())).thenAnswer((_) async {});
        when(() => repo.getMatches(any())).thenAnswer((_) async => []);
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(CreateCustomMatch(homeTeam: user1, awayTeam: user2)),
      verify: (_) {
        final captured =
            verify(() => repo.createCustomMatch(captureAny())).captured;
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
      act: (bloc) => bloc.add(CreateCustomMatch(homeTeam: user1, awayTeam: user2)),
      expect: () => [
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'loading', ViewStatus.loading),
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'failure', ViewStatus.failure),
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
      'success: gọi deleteMatch + add GetParticipantStats',
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
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'loading', ViewStatus.loading),
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'failure', ViewStatus.failure),
      ],
    );
  });

  group('AddParticipant', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không league ⇒ no-op',
      build: build,
      act: (bloc) => bloc.add(const AddParticipant('L1', 'U1')),
      verify: (_) => verifyNever(
          () => repo.addParticipant(leagueId: any(named: 'leagueId'), userId: any(named: 'userId'))),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'success: thêm + toast + load lại stats',
      build: () {
        when(() => repo.addParticipant(
              leagueId: any(named: 'leagueId'),
              userId: any(named: 'userId'),
            )).thenAnswer((_) async {});
        when(() => repo.getLeagueStats(any())).thenAnswer((_) async => []);
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(const AddParticipant('L1', 'U1')),
      verify: (_) {
        verify(() => repo.addParticipant(leagueId: 'L1', userId: 'U1')).called(1);
        expect(toasts.any((t) => t.contains('Thêm người chơi')), isTrue);
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'failure: emit failure',
      build: () {
        when(() => repo.addParticipant(
              leagueId: any(named: 'leagueId'),
              userId: any(named: 'userId'),
            )).thenThrow(Exception('x'));
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(const AddParticipant('L1', 'U1')),
      expect: () => [
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'loading', ViewStatus.loading),
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'failure', ViewStatus.failure),
      ],
    );
  });

  group('AddMultipleParticipants', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không league ⇒ no-op',
      build: build,
      act: (bloc) =>
          bloc.add(const AddMultipleParticipants('L1', ['U1', 'U2'])),
      verify: (_) => verifyNever(() => repo.addMultipleParticipants(
          leagueId: any(named: 'leagueId'),
          userIds: any(named: 'userIds'))),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'userIds rỗng ⇒ no-op',
      build: () => buildWithLeague(_league()),
      act: (bloc) => bloc.add(const AddMultipleParticipants('L1', [])),
      verify: (_) => verifyNever(() => repo.addMultipleParticipants(
          leagueId: any(named: 'leagueId'),
          userIds: any(named: 'userIds'))),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'success',
      build: () {
        when(() => repo.addMultipleParticipants(
              leagueId: any(named: 'leagueId'),
              userIds: any(named: 'userIds'),
            )).thenAnswer((_) async {});
        when(() => repo.getLeagueStats(any())).thenAnswer((_) async => []);
        return buildWithLeague(_league());
      },
      act: (bloc) =>
          bloc.add(const AddMultipleParticipants('L1', ['U1', 'U2'])),
      verify: (_) {
        verify(() => repo.addMultipleParticipants(
            leagueId: 'L1', userIds: ['U1', 'U2'])).called(1);
        expect(
          toasts.any((t) => t.contains('2 người chơi')),
          isTrue,
        );
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'failure: emit failure',
      build: () {
        when(() => repo.addMultipleParticipants(
              leagueId: any(named: 'leagueId'),
              userIds: any(named: 'userIds'),
            )).thenThrow(Exception('x'));
        return buildWithLeague(_league());
      },
      act: (bloc) =>
          bloc.add(const AddMultipleParticipants('L1', ['U1'])),
      expect: () => [
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'loading', ViewStatus.loading),
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'failure', ViewStatus.failure),
      ],
    );
  });

  group('GenerateRound failure path', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'không league ⇒ no-op',
      build: build,
      act: (bloc) => bloc.add(const GenerateRound()),
      verify: (_) => verifyNever(() => repo.generateRound(
          leagueId: any(named: 'leagueId'),
          teamIds: any(named: 'teamIds'))),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'state loading ⇒ no-op',
      build: () {
        final bloc = buildWithLeague(_league());
        bloc.emit(bloc.state.copyWith(
          participants: [_stat('A'), _stat('B')],
          viewStatus: ViewStatus.loading,
        ));
        return bloc;
      },
      act: (bloc) => bloc.add(const GenerateRound()),
      verify: (_) => verifyNever(() => repo.generateRound(
          leagueId: any(named: 'leagueId'),
          teamIds: any(named: 'teamIds'))),
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'repo throw: emit failure',
      build: () {
        when(() => repo.generateRound(
              leagueId: any(named: 'leagueId'),
              teamIds: any(named: 'teamIds'),
            )).thenThrow(Exception('x'));
        final bloc = buildWithLeague(_league());
        bloc.emit(bloc.state.copyWith(participants: [_stat('A'), _stat('B')]));
        return bloc;
      },
      act: (bloc) => bloc.add(const GenerateRound()),
      expect: () => [
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'loading', ViewStatus.loading),
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'failure', ViewStatus.failure),
      ],
    );
  });

  group('UpdateEsportMatch failure', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'repo throw: emit failure',
      build: () {
        when(() => repo.updateMatch(any())).thenThrow(Exception('x'));
        return buildWithLeague(_league());
      },
      act: (bloc) => bloc.add(UpdateEsportMatch(_match(homeScore: 1, awayScore: 0))),
      expect: () => [
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'loading', ViewStatus.loading),
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'failure', ViewStatus.failure),
      ],
    );
  });

  group('GetMatches', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'success: gắn user vào match',
      build: () {
        when(() => repo.getMatches('L1')).thenAnswer(
          (_) async => [_match(home: 'A', away: 'B')],
        );
        final bloc = build();
        const userA = GNUser(
          id: 'A',
          email: null,
          displayName: 'A',
          photoUrl: null,
          phoneNumber: null,
          role: 'user',
          fcmToken: '',
        );
        const userB = GNUser(
          id: 'B',
          email: null,
          displayName: 'B',
          photoUrl: null,
          phoneNumber: null,
          role: 'user',
          fcmToken: '',
        );
        bloc.emit(bloc.state.copyWith(users: [userA, userB]));
        return bloc;
      },
      act: (bloc) => bloc.add(const GetMatches('L1')),
      skip: 1,
      expect: () => [
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'success', ViewStatus.success)
            .having((s) => s.matches.first.homeTeam?.id, 'home', 'A')
            .having((s) => s.matches.first.awayTeam?.id, 'away', 'B'),
      ],
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'failure: emit failure',
      build: () {
        when(() => repo.getMatches(any())).thenThrow(Exception('x'));
        return build();
      },
      act: (bloc) => bloc.add(const GetMatches('L1')),
      skip: 1,
      expect: () => [
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'failure', ViewStatus.failure),
      ],
    );
  });

  group('GetParticipantStats', () {
    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'sort + load matches',
      build: () {
        when(() => repo.getLeagueStats('L1')).thenAnswer((_) async => [
              _stat('B', wins: 1),
              _stat('A', wins: 2),
            ]);
        when(() => repo.getMatches(any())).thenAnswer((_) async => []);
        return build();
      },
      act: (bloc) => bloc.add(const GetParticipantStats('L1')),
      verify: (_) {
        verify(() => repo.getMatches('L1')).called(1);
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'failure: emit failure',
      build: () {
        when(() => repo.getLeagueStats(any())).thenThrow(Exception('x'));
        return build();
      },
      act: (bloc) => bloc.add(const GetParticipantStats('L1')),
      skip: 1,
      expect: () => [
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'failure', ViewStatus.failure),
      ],
    );
  });

  group('GetLeague stream listeners', () {
    test('listenForLeagueStats emit → add GetParticipantsAndMatches '
        'khi state.league đã có', () async {
      final statsCtrl = StreamController<List<GNEsportLeagueStat>>();
      final matchesCtrl = StreamController<List<GNEsportMatch>>();
      final leagueCtrl = StreamController<GNEsportLeague>();
      addTearDown(() {
        statsCtrl.close();
        matchesCtrl.close();
        leagueCtrl.close();
      });

      when(() => repo.listenForLeagueStats(any()))
          .thenAnswer((_) => statsCtrl.stream);
      when(() => repo.listenForMatchesUpdated(any()))
          .thenAnswer((_) => matchesCtrl.stream);
      when(() => repo.listenForLeagueUpdated(any()))
          .thenAnswer((_) => leagueCtrl.stream);
      when(() => repo.getLeague('L1'))
          .thenAnswer((_) async => _league(id: 'L1'));
      when(() => repo.getParticipantsAndMatches(any())).thenAnswer(
        (_) async => const LeagueDetailData(participants: [], matches: []),
      );

      final bloc = build();
      bloc.add(const GetLeague('L1'));
      // Cho future getLeague resolve trước khi push stats event.
      await Future<void>.delayed(Duration.zero);

      statsCtrl.add([]);
      await Future<void>.delayed(Duration.zero);

      verify(() => repo.getParticipantsAndMatches('L1')).called(greaterThan(0));
      await bloc.close();
    });

    test('listenForMatchesUpdated emit → add UpdateMatches', () async {
      final statsCtrl = StreamController<List<GNEsportLeagueStat>>();
      final matchesCtrl = StreamController<List<GNEsportMatch>>();
      final leagueCtrl = StreamController<GNEsportLeague>();
      addTearDown(() {
        statsCtrl.close();
        matchesCtrl.close();
        leagueCtrl.close();
      });

      when(() => repo.listenForLeagueStats(any()))
          .thenAnswer((_) => statsCtrl.stream);
      when(() => repo.listenForMatchesUpdated(any()))
          .thenAnswer((_) => matchesCtrl.stream);
      when(() => repo.listenForLeagueUpdated(any()))
          .thenAnswer((_) => leagueCtrl.stream);
      when(() => repo.getLeague('L1'))
          .thenAnswer((_) async => _league(id: 'L1'));

      final bloc = build();
      bloc.add(const GetLeague('L1'));
      await Future<void>.delayed(Duration.zero);

      matchesCtrl.add([_match()]);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.matches, hasLength(1));
      await bloc.close();
    });

    test('listenForLeagueUpdated emit → add UpdateLeague (xử lý onError không crash)',
        () async {
      final statsCtrl = StreamController<List<GNEsportLeagueStat>>();
      final matchesCtrl = StreamController<List<GNEsportMatch>>();
      final leagueCtrl = StreamController<GNEsportLeague>();
      addTearDown(() {
        statsCtrl.close();
        matchesCtrl.close();
        leagueCtrl.close();
      });

      when(() => repo.listenForLeagueStats(any()))
          .thenAnswer((_) => statsCtrl.stream);
      when(() => repo.listenForMatchesUpdated(any()))
          .thenAnswer((_) => matchesCtrl.stream);
      when(() => repo.listenForLeagueUpdated(any()))
          .thenAnswer((_) => leagueCtrl.stream);
      when(() => repo.getLeague('L1'))
          .thenAnswer((_) async => _league(id: 'L1'));
      when(() => repo.getParticipantsAndMatches(any())).thenAnswer(
        (_) async => const LeagueDetailData(participants: [], matches: []),
      );

      final bloc = build();
      bloc.add(const GetLeague('L1'));
      await Future<void>.delayed(Duration.zero);

      // Push update — covers onData branch
      leagueCtrl.add(_league(id: 'L1', status: 'finished'));
      await Future<void>.delayed(Duration.zero);

      // Push error — covers onError branch (no-op trong code)
      leagueCtrl.addError(Exception('boom'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.league?.status, 'finished');
      await bloc.close();
    });
  });

  test('close() huỷ subscriptions không crash', () async {
    final bloc = build();
    bloc.add(const GetLeague('L1'));
    when(() => repo.getLeague(any())).thenAnswer((_) async => _league());
    await Future<void>.delayed(Duration.zero);
    await bloc.close();
    expect(bloc.isClosed, isTrue);
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
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'loading', ViewStatus.loading),
        isA<TournamentDetailState>()
            .having((s) => s.viewStatus, 'failure', ViewStatus.failure),
      ],
    );
  });

  group('GetParticipantStats branches', () {
    final user1 = const GNUser(
      id: 'A',
      email: null,
      displayName: 'A',
      photoUrl: null,
      phoneNumber: null,
      role: 'user',
      fcmToken: '',
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'thu thập user khi participant.user != null',
      build: () {
        when(() => repo.getLeagueStats('L1')).thenAnswer((_) async => [
              _stat('A', wins: 1, user: user1),
              _stat('B'),
            ]);
        when(() => repo.getMatches(any())).thenAnswer((_) async => []);
        return build();
      },
      act: (bloc) => bloc.add(const GetParticipantStats('L1')),
      verify: (bloc) {
        expect(bloc.state.users, [user1]);
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'tie-break theo goalDifference',
      build: () {
        // A và B cùng points=3, A goalDiff=+5, B goalDiff=+1
        when(() => repo.getLeagueStats('L1')).thenAnswer((_) async => [
              _stat('B', wins: 1, goals: 2, goalsConceded: 1),
              _stat('A', wins: 1, goals: 6, goalsConceded: 1),
            ]);
        when(() => repo.getMatches(any())).thenAnswer((_) async => []);
        return build();
      },
      act: (bloc) => bloc.add(const GetParticipantStats('L1')),
      verify: (bloc) {
        expect(bloc.state.participants.first.userId, 'A');
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'tie-break theo goals',
      build: () {
        // points và goalDiff bằng nhau, A goals nhiều hơn
        when(() => repo.getLeagueStats('L1')).thenAnswer((_) async => [
              _stat('B', wins: 1, losses: 1, goals: 2, goalsConceded: 1),
              _stat('A', wins: 1, losses: 1, goals: 5, goalsConceded: 4),
            ]);
        when(() => repo.getMatches(any())).thenAnswer((_) async => []);
        return build();
      },
      act: (bloc) => bloc.add(const GetParticipantStats('L1')),
      verify: (bloc) {
        expect(bloc.state.participants.first.userId, 'A');
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'tie-break theo matchesPlayed (cuối cùng)',
      build: () {
        // points, goalDiff, goals đều bằng. A đá nhiều trận hơn.
        when(() => repo.getLeagueStats('L1')).thenAnswer((_) async => [
              _stat('B', wins: 0, draws: 1, goals: 1, goalsConceded: 1),
              _stat('A', wins: 0, draws: 1, losses: 1, goals: 1, goalsConceded: 1),
            ]);
        when(() => repo.getMatches(any())).thenAnswer((_) async => []);
        return build();
      },
      act: (bloc) => bloc.add(const GetParticipantStats('L1')),
      verify: (bloc) {
        // A đá 2 trận, B đá 1 trận → A đứng trên
        expect(bloc.state.participants.first.userId, 'A');
      },
    );
  });

  group('GetParticipantsAndMatches user collection', () {
    final user1 = const GNUser(
      id: 'A',
      email: null,
      displayName: 'A',
      photoUrl: null,
      phoneNumber: null,
      role: 'user',
      fcmToken: '',
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'thu thập user khi participant.user != null',
      build: () {
        when(() => repo.getParticipantsAndMatches('L1')).thenAnswer(
          (_) async => LeagueDetailData(
            participants: [
              _stat('A', wins: 1, user: user1),
              _stat('B'),
            ],
            matches: const [],
          ),
        );
        return build();
      },
      act: (bloc) => bloc.add(const GetParticipantsAndMatches('L1')),
      verify: (bloc) {
        expect(bloc.state.users, [user1]);
      },
    );

    blocTest<TournamentDetailBloc, TournamentDetailState>(
      'tie-break matchesPlayed cuối cùng',
      build: () {
        when(() => repo.getParticipantsAndMatches('L1')).thenAnswer(
          (_) async => LeagueDetailData(
            participants: [
              _stat('B', draws: 1, goals: 1, goalsConceded: 1),
              _stat('A', draws: 1, losses: 1, goals: 1, goalsConceded: 1),
            ],
            matches: const [],
          ),
        );
        return build();
      },
      act: (bloc) =>
          bloc.add(const GetParticipantsAndMatches('L1')),
      verify: (bloc) {
        expect(bloc.state.participants.first.userId, 'A');
      },
    );
  });
}
