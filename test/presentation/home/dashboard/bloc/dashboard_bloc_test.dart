import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/presentation/home/dashboard/bloc/dashboard_bloc.dart';
import 'package:pes_arena/presentation/home/dashboard/models/dashboard_stats.dart';
import 'package:pes_arena/presentation/home/dashboard/models/recent_match_summary.dart';

class _MockRepo extends Mock implements EsportLeagueRepository {}

class _MockAuth extends Mock implements GNAuth {}

class _MockUser extends Mock implements User {}

GNEsportLeague _league({
  required String id,
  required String name,
  required DateTime startDate,
  DateTime? endDate,
  String status = 'finished',
  List<String> participants = const ['u1', 'u2'],
}) {
  return GNEsportLeague(
    id: id,
    ownerId: 'owner',
    groupId: 'g1',
    name: name,
    startDate: startDate,
    endDate: endDate,
    isActive: true,
    description: '',
    participants: participants,
    status: status,
  );
}

GNEsportLeagueStat _stat({
  required String userId,
  required String leagueId,
  required int wins,
  required int draws,
  required int losses,
  required int goals,
  required int goalsConceded,
}) {
  return GNEsportLeagueStat(
    id: '$leagueId-$userId',
    userId: userId,
    leagueId: leagueId,
    matchesPlayed: wins + draws + losses,
    goals: goals,
    goalsConceded: goalsConceded,
    wins: wins,
    draws: draws,
    losses: losses,
  );
}

GNEsportMatch _match({
  required String id,
  required String leagueId,
  required DateTime date,
  required String homeTeamId,
  required String awayTeamId,
  required int homeScore,
  required int awayScore,
}) {
  return GNEsportMatch(
    id: id,
    homeTeamId: homeTeamId,
    awayTeamId: awayTeamId,
    homeScore: homeScore,
    awayScore: awayScore,
    date: date,
    isFinished: true,
    leagueId: leagueId,
    homeTeam: GNUser(
      id: homeTeamId,
      displayName: homeTeamId == 'u1' ? 'Bạn' : 'Player $homeTeamId',
      phoneNumber: null,
      email: null,
      photoUrl: null,
      role: 'user',
      fcmToken: '',
    ),
    awayTeam: GNUser(
      id: awayTeamId,
      displayName: awayTeamId == 'u1' ? 'Bạn' : 'Player $awayTeamId',
      phoneNumber: null,
      email: null,
      photoUrl: null,
      role: 'user',
      fcmToken: '',
    ),
  );
}

void main() {
  late _MockRepo repo;
  late _MockAuth auth;
  late _MockUser user;

  setUp(() {
    repo = _MockRepo();
    auth = _MockAuth();
    user = _MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('u1');
  });

  blocTest<DashboardBloc, DashboardState>(
    'LoadDashboard tính thống kê champion/runner-up và sort 10 trận gần nhất',
    build: () {
      final leagues = [
        _league(
          id: 'l1',
          name: 'Champions Cup',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 10),
        ),
        _league(
          id: 'l2',
          name: 'Runner Cup',
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 10),
        ),
        _league(
          id: 'l3',
          name: 'Ongoing Cup',
          startDate: DateTime(2026, 3, 1),
          status: 'ongoing',
        ),
      ];
      when(() => repo.getMyLeagues()).thenAnswer((_) async => leagues);
      when(() => repo.getParticipantsAndMatches('l1')).thenAnswer(
        (_) async => LeagueDetailData(
          participants: [
            _stat(
              userId: 'u1',
              leagueId: 'l1',
              wins: 3,
              draws: 0,
              losses: 0,
              goals: 9,
              goalsConceded: 1,
            ),
            _stat(
              userId: 'u2',
              leagueId: 'l1',
              wins: 1,
              draws: 0,
              losses: 2,
              goals: 4,
              goalsConceded: 8,
            ),
          ],
          matches: List.generate(
            6,
            (i) => _match(
              id: 'l1-m$i',
              leagueId: 'l1',
              date: DateTime(2026, 4, i + 1),
              homeTeamId: 'u1',
              awayTeamId: 'u2',
              homeScore: 2,
              awayScore: 1,
            ),
          ),
        ),
      );
      when(() => repo.getParticipantsAndMatches('l2')).thenAnswer(
        (_) async => LeagueDetailData(
          participants: [
            _stat(
              userId: 'u2',
              leagueId: 'l2',
              wins: 2,
              draws: 0,
              losses: 0,
              goals: 5,
              goalsConceded: 2,
            ),
            _stat(
              userId: 'u1',
              leagueId: 'l2',
              wins: 1,
              draws: 0,
              losses: 1,
              goals: 4,
              goalsConceded: 3,
            ),
          ],
          matches: List.generate(
            6,
            (i) => _match(
              id: 'l2-m$i',
              leagueId: 'l2',
              date: DateTime(2026, 5, i + 1),
              homeTeamId: 'u2',
              awayTeamId: 'u1',
              homeScore: i.isEven ? 1 : 2,
              awayScore: i.isEven ? 1 : 0,
            ),
          ),
        ),
      );
      when(() => repo.getParticipantsAndMatches('l3')).thenAnswer(
        (_) async => LeagueDetailData(
          participants: [
            _stat(
              userId: 'u1',
              leagueId: 'l3',
              wins: 1,
              draws: 0,
              losses: 0,
              goals: 3,
              goalsConceded: 0,
            ),
          ],
          matches: const [],
        ),
      );

      return DashboardBloc(leagueRepository: repo, auth: auth);
    },
    act: (bloc) => bloc.add(LoadDashboard()),
    expect: () => [
      isA<DashboardState>().having(
        (state) => state.viewStatus,
        'status',
        ViewStatus.loading,
      ),
      isA<DashboardState>()
          .having((state) => state.viewStatus, 'status', ViewStatus.success)
          .having((state) => state.stats?.tournamentsJoined, 'joined', 3)
          .having((state) => state.stats?.finishedTournaments, 'finished', 2)
          .having((state) => state.stats?.championCount, 'champion', 1)
          .having((state) => state.stats?.runnerUpCount, 'runner-up', 1)
          .having(
            (state) => state.stats?.lastChampionAt,
            'lastChampionAt',
            DateTime(2026, 1, 10),
          )
          .having(
            (state) => state.stats?.recentMatches.length,
            'recentMatches',
            10,
          )
          .having(
            (state) => state.stats?.recentMatches.first.matchId,
            'newest match',
            'l2-m5',
          )
          .having(
            (state) => state.stats?.recentMatches.first.result,
            'newest result',
            MatchResult.loss,
          ),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'LoadDashboard dùng goal difference để xác định vô địch khi bằng điểm',
    build: () {
      final league = _league(
        id: 'l1',
        name: 'Tie Cup',
        startDate: DateTime(2026, 1, 1),
      );
      when(() => repo.getMyLeagues()).thenAnswer((_) async => [league]);
      when(() => repo.getParticipantsAndMatches('l1')).thenAnswer(
        (_) async => LeagueDetailData(
          participants: [
            _stat(
              userId: 'u1',
              leagueId: 'l1',
              wins: 2,
              draws: 0,
              losses: 0,
              goals: 8,
              goalsConceded: 1,
            ),
            _stat(
              userId: 'u2',
              leagueId: 'l1',
              wins: 2,
              draws: 0,
              losses: 0,
              goals: 8,
              goalsConceded: 4,
            ),
          ],
          matches: const [],
        ),
      );
      return DashboardBloc(leagueRepository: repo, auth: auth);
    },
    act: (bloc) => bloc.add(LoadDashboard()),
    skip: 1,
    expect: () => [
      isA<DashboardState>()
          .having((state) => state.viewStatus, 'status', ViewStatus.success)
          .having((state) => state.stats?.championCount, 'champion', 1),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'LoadDashboard dùng goals làm tie-breaker cuối và cập nhật lastChampionAt mới nhất',
    build: () {
      final leagues = [
        _league(
          id: 'l1',
          name: 'Old Cup',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 2),
        ),
        _league(
          id: 'l2',
          name: 'New Cup',
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 2),
        ),
      ];
      when(() => repo.getMyLeagues()).thenAnswer((_) async => leagues);
      for (final league in leagues) {
        when(() => repo.getParticipantsAndMatches(league.id)).thenAnswer(
          (_) async => LeagueDetailData(
            participants: [
              _stat(
                userId: 'u1',
                leagueId: league.id,
                wins: 1,
                draws: 0,
                losses: 0,
                goals: 5,
                goalsConceded: 2,
              ),
              _stat(
                userId: 'u2',
                leagueId: league.id,
                wins: 1,
                draws: 0,
                losses: 0,
                goals: 4,
                goalsConceded: 1,
              ),
            ],
            matches: const [],
          ),
        );
      }
      return DashboardBloc(leagueRepository: repo, auth: auth);
    },
    act: (bloc) => bloc.add(LoadDashboard()),
    skip: 1,
    expect: () => [
      isA<DashboardState>()
          .having((state) => state.viewStatus, 'status', ViewStatus.success)
          .having((state) => state.stats?.championCount, 'champions', 2)
          .having(
            (state) => state.stats?.lastChampionAt,
            'lastChampionAt',
            DateTime(2026, 2, 2),
          ),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'LoadDashboard emit failure khi repository lỗi',
    build: () {
      when(() => repo.getMyLeagues()).thenThrow(Exception('network'));
      return DashboardBloc(leagueRepository: repo, auth: auth);
    },
    act: (bloc) => bloc.add(LoadDashboard()),
    expect: () => [
      isA<DashboardState>().having(
        (state) => state.viewStatus,
        'status',
        ViewStatus.loading,
      ),
      isA<DashboardState>()
          .having((state) => state.viewStatus, 'status', ViewStatus.failure)
          .having(
            (state) => state.errorMessage,
            'errorMessage',
            contains('network'),
          ),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'LoadDashboard emit failure khi user chưa đăng nhập',
    build: () {
      when(() => auth.currentUser).thenReturn(null);
      return DashboardBloc(leagueRepository: repo, auth: auth);
    },
    act: (bloc) => bloc.add(LoadDashboard()),
    expect: () => [
      isA<DashboardState>().having(
        (state) => state.viewStatus,
        'status',
        ViewStatus.loading,
      ),
      isA<DashboardState>()
          .having((state) => state.viewStatus, 'status', ViewStatus.failure)
          .having(
            (state) => state.errorMessage,
            'errorMessage',
            'Người dùng chưa đăng nhập',
          ),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'LoadDashboard không load lại khi state đang loading',
    seed: () => const DashboardState(viewStatus: ViewStatus.loading),
    build: () => DashboardBloc(leagueRepository: repo, auth: auth),
    act: (bloc) => bloc.add(LoadDashboard()),
    expect: () => <DashboardState>[],
    verify: (_) {
      verifyNever(() => repo.getMyLeagues());
    },
  );

  blocTest<DashboardBloc, DashboardState>(
    'RefreshDashboard giữ stats cũ trong state loading',
    seed: () => const DashboardState(
      viewStatus: ViewStatus.success,
      stats: DashboardStats(
        tournamentsJoined: 1,
        finishedTournaments: 0,
        championCount: 0,
        runnerUpCount: 0,
        lastChampionAt: null,
        recentMatches: [],
      ),
    ),
    build: () {
      when(() => repo.getMyLeagues()).thenAnswer((_) async => const []);
      return DashboardBloc(leagueRepository: repo, auth: auth);
    },
    act: (bloc) => bloc.add(RefreshDashboard()),
    expect: () => [
      isA<DashboardState>()
          .having((state) => state.viewStatus, 'status', ViewStatus.loading)
          .having((state) => state.stats?.tournamentsJoined, 'old stats', 1),
      isA<DashboardState>()
          .having((state) => state.viewStatus, 'status', ViewStatus.success)
          .having((state) => state.stats?.tournamentsJoined, 'new stats', 0),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'LoadDashboard bỏ league không có participant uid và finished không có stat',
    build: () {
      final leagues = [
        _league(
          id: 'l1',
          name: 'Missing Stat Cup',
          startDate: DateTime(2026, 1, 1),
        ),
        _league(
          id: 'l2',
          name: 'Not Joined Cup',
          startDate: DateTime(2026, 2, 1),
          participants: const ['u2'],
        ),
      ];
      when(() => repo.getMyLeagues()).thenAnswer((_) async => leagues);
      when(() => repo.getParticipantsAndMatches('l1')).thenAnswer(
        (_) async => LeagueDetailData(
          participants: [
            _stat(
              userId: 'u2',
              leagueId: 'l1',
              wins: 1,
              draws: 0,
              losses: 0,
              goals: 1,
              goalsConceded: 0,
            ),
          ],
          matches: [
            GNEsportMatch(
              id: 'unfinished',
              homeTeamId: 'u1',
              awayTeamId: 'u2',
              homeScore: 0,
              awayScore: 0,
              date: DateTime(2026, 1, 1),
              isFinished: false,
              leagueId: 'l1',
            ),
          ],
        ),
      );
      return DashboardBloc(leagueRepository: repo, auth: auth);
    },
    act: (bloc) => bloc.add(LoadDashboard()),
    skip: 1,
    expect: () => [
      isA<DashboardState>()
          .having((state) => state.viewStatus, 'status', ViewStatus.success)
          .having((state) => state.stats?.tournamentsJoined, 'joined', 1)
          .having((state) => state.stats?.finishedTournaments, 'finished', 0)
          .having(
            (state) => state.stats?.recentMatches,
            'recentMatches',
            isEmpty,
          ),
    ],
  );
}
