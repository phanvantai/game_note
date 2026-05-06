import 'package:pes_arena/firebase/firestore/esport/group/stats/gn_esport_group_stats_summary.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';

/// Pure client-side aggregation for year-filtered group overview.
///
/// Takes leagues + their per-league stats, filters by year, and returns a
/// synthetic [GNEsportGroupStatsSummary] that [GroupOverviewCalculator] can
/// consume directly — no Cloud Function required.
class GroupOverviewYearFilter {
  const GroupOverviewYearFilter._();

  /// Build a synthetic summary for leagues whose [GNEsportLeague.startDate]
  /// falls in [year].
  ///
  /// [statsByLeague] maps leagueId → stats list fetched via
  /// [EsportLeagueRepository.getLeagueStats]. Missing entries are treated as
  /// empty (league had no recorded stats yet).
  static GNEsportGroupStatsSummary aggregate({
    required List<GNEsportLeague> leagues,
    required int year,
    required Map<String, List<GNEsportLeagueStat>> statsByLeague,
  }) {
    final filtered = leagues.where((l) => l.startDate.year == year).toList();
    if (filtered.isEmpty) {
      return GNEsportGroupStatsSummary.empty(
        filtered.isEmpty ? '' : filtered.first.groupId,
      );
    }

    final groupId = filtered.first.groupId;
    final finishedLeagues =
        filtered.where((l) => l.status == 'finished').toList();

    // Accumulate per-player stats across all leagues in the selected year.
    final acc = <String, _Acc>{};

    for (final league in filtered) {
      final leagueStats =
          statsByLeague[league.id] ?? const <GNEsportLeagueStat>[];
      for (final stat in leagueStats) {
        final a = acc.putIfAbsent(stat.userId, () => _Acc(stat.userId));
        a.matches += stat.matchesPlayed;
        a.wins += stat.wins;
        a.draws += stat.draws;
        a.losses += stat.losses;
        a.goals += stat.goals;
        a.goalsConceded += stat.goalsConceded;
      }
    }

    // Compute championships / runnerUps / finishedLeaguesJoined from finished
    // leagues only. Standings are sorted the same way as TournamentDetailBloc:
    // wins desc → goal-diff desc → matches-played desc → userId asc.
    for (final league in finishedLeagues) {
      final stats =
          statsByLeague[league.id] ?? const <GNEsportLeagueStat>[];
      if (stats.isEmpty) continue;

      for (final stat in stats) {
        acc.putIfAbsent(stat.userId, () => _Acc(stat.userId))
            .finishedLeaguesJoined++;
      }

      final sorted = List.of(stats)
        ..sort((a, b) {
          if (a.wins != b.wins) return b.wins.compareTo(a.wins);
          final aDiff = a.goals - a.goalsConceded;
          final bDiff = b.goals - b.goalsConceded;
          if (aDiff != bDiff) return bDiff.compareTo(aDiff);
          if (a.matchesPlayed != b.matchesPlayed) {
            return b.matchesPlayed.compareTo(a.matchesPlayed);
          }
          return a.userId.compareTo(b.userId);
        });

      if (sorted.isNotEmpty) {
        acc.putIfAbsent(sorted[0].userId, () => _Acc(sorted[0].userId))
            .championships++;
      }
      if (sorted.length >= 2) {
        acc.putIfAbsent(sorted[1].userId, () => _Acc(sorted[1].userId))
            .runnerUps++;
      }
    }

    final playerEntries = acc.values
        .map(
          (e) => GNEsportGroupPlayerEntry(
            userId: e.userId,
            displayName: '',
            photoUrl: null,
            matches: e.matches,
            wins: e.wins,
            draws: e.draws,
            losses: e.losses,
            goals: e.goals,
            goalsConceded: e.goalsConceded,
            championships: e.championships,
            runnerUps: e.runnerUps,
            finishedLeaguesJoined: e.finishedLeaguesJoined,
          ),
        )
        .toList();

    return GNEsportGroupStatsSummary(
      groupId: groupId,
      totalLeagues: filtered.length,
      finishedLeagues: finishedLeagues.length,
      playerStats: playerEntries,
      updatedAt: null,
      schemaVersion: GNEsportGroupStatsSummary.kCurrentSchemaVersion,
    );
  }
}

class _Acc {
  final String userId;
  int matches = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  int goals = 0;
  int goalsConceded = 0;
  int championships = 0;
  int runnerUps = 0;
  int finishedLeaguesJoined = 0;

  _Acc(this.userId);
}
