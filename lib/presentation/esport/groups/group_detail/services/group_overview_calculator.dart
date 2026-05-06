import 'package:pes_arena/firebase/firestore/esport/group/stats/gn_esport_group_stats_summary.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/models/group_overview.dart';

/// Default qualification gates for rate-based awards. Tunable consts;
/// can be lifted to settings later if needed.
const int kMinFinishedLeagues = 5;
const int kMinMatches = 5;

/// Pure transform: server-maintained summary doc → presentation model
/// with awards computed client-side. Awards thresholds live here, not
/// on the server, so we can tune without redeploying functions.
///
/// `users` provides fresh `GNUser` objects (with photoUrl) keyed by id;
/// the bloc fetches these per-load so avatars always reflect the
/// current user docs even when the summary doc only stores displayName.
class GroupOverviewCalculator {
  const GroupOverviewCalculator._();

  static GroupOverview compute({
    required GNEsportGroupStatsSummary summary,
    Map<String, GNUser> users = const {},
    Set<String> deactivatedIds = const {},
    int minFinishedLeagues = kMinFinishedLeagues,
    int minMatches = kMinMatches,
  }) {
    final allPlayers = summary.playerStats;
    if (allPlayers.isEmpty && summary.totalLeagues == 0) {
      return const GroupOverview.empty();
    }

    final activePlayers = deactivatedIds.isEmpty
        ? allPlayers
        : allPlayers.where((e) => !deactivatedIds.contains(e.userId)).toList();

    GNUser toUser(GNEsportGroupPlayerEntry e) => _toUser(e, users);

    final playerStats = activePlayers
        .map((e) => GroupPlayerStats(
              player: toUser(e),
              matches: e.matches,
              wins: e.wins,
              draws: e.draws,
              losses: e.losses,
              goals: e.goals,
              goalsConceded: e.goalsConceded,
            ))
        .toList()
      ..sort((a, b) {
        if (a.winRate != b.winRate) return b.winRate.compareTo(a.winRate);
        if (a.matches != b.matches) return b.matches.compareTo(a.matches);
        return _displayName(a.player).compareTo(_displayName(b.player));
      });

    // Aggregate from ALL players to preserve group history accuracy.
    final totalPlayerMatches =
        allPlayers.fold<int>(0, (acc, e) => acc + e.matches);
    final totalGoals = allPlayers.fold<int>(0, (acc, e) => acc + e.goals);

    return GroupOverview(
      totalLeagues: summary.totalLeagues,
      finishedLeagues: summary.finishedLeagues,
      // Each match counts twice in player-aggregate (home + away rows),
      // so halve to get actual match count.
      totalMatchesPlayed: totalPlayerMatches ~/ 2,
      totalGoals: totalGoals,
      champion: _bestRate(
        kind: GroupAwardKind.champion,
        players: activePlayers,
        toUser: toUser,
        numerator: (e) => e.championships,
        sample: (e) => e.finishedLeaguesJoined,
        minSample: minFinishedLeagues,
      ),
      runnerUpKing: _bestRate(
        kind: GroupAwardKind.runnerUp,
        players: activePlayers,
        toUser: toUser,
        numerator: (e) => e.runnerUps,
        sample: (e) => e.finishedLeaguesJoined,
        minSample: minFinishedLeagues,
      ),
      drawKing: _drawKing(activePlayers, toUser),
      ironDefense: _ironDefense(activePlayers, toUser, minMatches),
      master: _master(activePlayers, toUser, minMatches),
      playerStats: playerStats,
    );
  }

  static GroupAward? _bestRate({
    required GroupAwardKind kind,
    required List<GNEsportGroupPlayerEntry> players,
    required GNUser Function(GNEsportGroupPlayerEntry) toUser,
    required int Function(GNEsportGroupPlayerEntry) numerator,
    required int Function(GNEsportGroupPlayerEntry) sample,
    required int minSample,
  }) {
    GNEsportGroupPlayerEntry? best;
    double bestRate = -1;
    for (final p in players) {
      final s = sample(p);
      if (s < minSample) continue;
      final n = numerator(p);
      final rate = n / s;
      if (best == null ||
          rate > bestRate ||
          (rate == bestRate && p.matches > best.matches) ||
          (rate == bestRate &&
              p.matches == best.matches &&
              _displayNameOf(p).compareTo(_displayNameOf(best)) < 0)) {
        best = p;
        bestRate = rate;
      }
    }
    if (best == null || bestRate <= 0) return null;
    return GroupAward(
      kind: kind,
      player: toUser(best),
      value: bestRate,
      sampleSize: sample(best),
      numerator: numerator(best),
    );
  }

  static GroupAward? _drawKing(
    List<GNEsportGroupPlayerEntry> players,
    GNUser Function(GNEsportGroupPlayerEntry) toUser,
  ) {
    GNEsportGroupPlayerEntry? top;
    for (final p in players) {
      if (p.draws <= 0) continue;
      if (top == null ||
          p.draws > top.draws ||
          (p.draws == top.draws && p.matches > top.matches) ||
          (p.draws == top.draws &&
              p.matches == top.matches &&
              _displayNameOf(p).compareTo(_displayNameOf(top)) < 0)) {
        top = p;
      }
    }
    if (top == null) return null;
    return GroupAward(
      kind: GroupAwardKind.drawKing,
      player: toUser(top),
      value: top.draws.toDouble(),
      sampleSize: top.matches,
      numerator: top.draws,
    );
  }

  static GroupAward? _ironDefense(
    List<GNEsportGroupPlayerEntry> players,
    GNUser Function(GNEsportGroupPlayerEntry) toUser,
    int minMatches,
  ) {
    GNEsportGroupPlayerEntry? top;
    double bestRate = double.infinity;
    for (final p in players) {
      if (p.matches < minMatches) continue;
      final rate = p.goalsConceded / p.matches;
      if (top == null ||
          rate < bestRate ||
          (rate == bestRate && p.matches > top.matches) ||
          (rate == bestRate &&
              p.matches == top.matches &&
              _displayNameOf(p).compareTo(_displayNameOf(top)) < 0)) {
        top = p;
        bestRate = rate;
      }
    }
    if (top == null) return null;
    return GroupAward(
      kind: GroupAwardKind.ironDefense,
      player: toUser(top),
      value: bestRate,
      sampleSize: top.matches,
      numerator: top.goalsConceded,
    );
  }

  static GroupAward? _master(
    List<GNEsportGroupPlayerEntry> players,
    GNUser Function(GNEsportGroupPlayerEntry) toUser,
    int minMatches,
  ) {
    GNEsportGroupPlayerEntry? top;
    double bestRate = -1;
    for (final p in players) {
      if (p.matches < minMatches) continue;
      final rate = p.wins / p.matches;
      if (top == null ||
          rate > bestRate ||
          (rate == bestRate && p.matches > top.matches) ||
          (rate == bestRate &&
              p.matches == top.matches &&
              _displayNameOf(p).compareTo(_displayNameOf(top)) < 0)) {
        top = p;
        bestRate = rate;
      }
    }
    if (top == null || bestRate <= 0) return null;
    return GroupAward(
      kind: GroupAwardKind.master,
      player: toUser(top),
      value: bestRate,
      sampleSize: top.matches,
      numerator: top.wins,
    );
  }

  /// Prefer the live `users` map (fresh photoUrl from the users
  /// collection); fall back to the summary entry when the user doc
  /// hasn't been fetched yet (cache hit before the bloc completes
  /// the user lookup).
  static GNUser _toUser(
    GNEsportGroupPlayerEntry e,
    Map<String, GNUser> users,
  ) {
    final fresh = users[e.userId];
    if (fresh != null) return fresh;
    return GNUser(
      id: e.userId,
      displayName: e.displayName.isEmpty ? 'Người chơi' : e.displayName,
      phoneNumber: null,
      email: null,
      photoUrl: e.photoUrl,
      role: 'user',
      fcmToken: '',
      // Mark as placeholder when the server hasn't filled in a real
      // displayName yet — keeps the existing widget behaviour from
      // the prior client-side version.
      isPlaceholder: e.displayName.isEmpty,
    );
  }

  static String _displayNameOf(GNEsportGroupPlayerEntry e) =>
      e.displayName.isEmpty ? e.userId : e.displayName;

  static String _displayName(GNUser u) => u.displayName ?? u.id;
}
