import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pes_arena/data/sync/mapping_target.dart';
import 'package:pes_arena/data/sync/migration_plan.dart';
import 'package:pes_arena/data/sync/sync_remote_gateway.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/offline/domain/entities/league_model.dart';
import 'package:pes_arena/offline/domain/entities/match_model.dart';

/// Provider cho random id (Firestore auto-id). Cho phép test inject id cố định.
typedef IdGenerator = String Function();

class OfflineToOnlineMigrator {
  OfflineToOnlineMigrator(
    this._gateway, {
    IdGenerator? idGenerator,
  }) : _newId = idGenerator ?? _defaultIdGenerator;

  final SyncRemoteGateway _gateway;
  final IdGenerator _newId;

  static String _defaultIdGenerator() =>
      FirebaseFirestore.instance.collection('_ids').doc().id;

  /// Pure: build kế hoạch ghi từ data offline + mappings. Không chạm Firestore.
  /// Throw `ArgumentError` nếu input không hợp lệ; throw `PlanTooLargeException`
  /// nếu plan vượt 500 ops.
  MigrationPlan buildPlan({
    required LeagueModel offlineLeague,
    required String groupId,
    required String currentUserUid,
    required Map<int, MappingTarget> mappings,
  }) {
    _validate(offlineLeague, mappings);

    // 1) Resolve mappings → Map<offlinePlayerId, onlineUid> + list placeholder
    //    cần tạo. Sinh id placeholder trước (Firestore auto-id) để có thể
    //    tham chiếu trong stats + matches.
    final placeholderUsers = <PlannedPlaceholder>[];
    final playerIdToUid = <int, String>{};
    for (final entry in mappings.entries) {
      final target = entry.value;
      switch (target) {
        case MapToExisting(uid: final uid):
          playerIdToUid[entry.key] = uid;
        case CreatePlaceholder(displayName: final name):
          final id = 'placeholder_${_newId()}';
          placeholderUsers.add(
            PlannedPlaceholder(id: id, displayName: name),
          );
          playerIdToUid[entry.key] = id;
      }
    }
    _ensureNoDuplicateUids(playerIdToUid);

    final allUids = playerIdToUid.values.toSet().toList();

    // 2) League doc data.
    final leagueId = _newId();
    final leagueData = <String, dynamic>{
      GNEsportLeague.fieldOwnerId: currentUserUid,
      GNEsportLeague.fieldGroupId: groupId,
      GNEsportLeague.fieldName: offlineLeague.name,
      GNEsportLeague.fieldStartDate:
          Timestamp.fromDate(offlineLeague.dateTime),
      GNEsportLeague.fieldEndDate: Timestamp.fromDate(offlineLeague.dateTime),
      GNEsportLeague.fieldIsActive: true,
      GNEsportLeague.fieldDescription:
          'Imported from offline #${offlineLeague.id}',
      GNEsportLeague.fieldStatus: 'finished',
      GNEsportLeague.fieldRankPayoutEnabled: false,
      GNEsportLeague.fieldRankPayouts: const <int>[],
      GNEsportLeague.fieldDefaultMatchCost: 50000,
    };

    // 3) Build matches first — stats reconciled from these.
    final matches = _buildOnlineMatches(
      offlineLeague: offlineLeague,
      leagueId: leagueId,
      playerIdToUid: playerIdToUid,
    );

    // 4) Compute per-uid stats from matches (client-side reconcile).
    final statDocs = _buildStatDocs(
      uids: allUids,
      leagueId: leagueId,
      matches: matches,
    );

    final plan = MigrationPlan(
      placeholderUsers: placeholderUsers,
      groupId: groupId,
      uidsToAddToGroup: allUids,
      leagueId: leagueId,
      leagueData: leagueData,
      participantUids: allUids,
      statDocs: statDocs,
      matches: matches,
    );

    if (plan.exceedsBatchLimit) {
      throw PlanTooLargeException(plan.totalOps);
    }
    return plan;
  }

  /// Commit plan đã build qua gateway. Atomic: fail = không có gì commit.
  Future<void> commit(MigrationPlan plan) => _gateway.commitBatch(plan);

  // ---------------- helpers ----------------

  void _validate(LeagueModel league, Map<int, MappingTarget> mappings) {
    if (mappings.isEmpty) {
      throw ArgumentError.value(
        mappings,
        'mappings',
        'Phải có ít nhất 1 mapping',
      );
    }
    final offlinePlayerIds = league.players
        .map((p) => p.playerModel.id)
        .whereType<int>()
        .toSet();
    final mappingKeys = mappings.keys.toSet();
    final missing = offlinePlayerIds.difference(mappingKeys);
    if (missing.isNotEmpty) {
      throw ArgumentError(
        'Thiếu mapping cho offline player ids: $missing',
      );
    }
    final unknown = mappingKeys.difference(offlinePlayerIds);
    if (unknown.isNotEmpty) {
      throw ArgumentError(
        'Mapping chứa offline player ids không có trong league: $unknown',
      );
    }
  }

  void _ensureNoDuplicateUids(Map<int, String> playerIdToUid) {
    final seen = <String, int>{};
    for (final entry in playerIdToUid.entries) {
      final existing = seen[entry.value];
      if (existing != null) {
        throw ArgumentError(
          'Hai offline player ($existing và ${entry.key}) cùng map vào uid ${entry.value}',
        );
      }
      seen[entry.value] = entry.key;
    }
  }

  List<GNEsportMatch> _buildOnlineMatches({
    required LeagueModel offlineLeague,
    required String leagueId,
    required Map<int, String> playerIdToUid,
  }) {
    final result = <GNEsportMatch>[];
    for (final round in offlineLeague.rounds) {
      for (final m in round.matches) {
        if (!_isCompleted(m)) continue;
        final homeId = m.home!.playerModel.id;
        final awayId = m.away!.playerModel.id;
        final homeUid = playerIdToUid[homeId];
        final awayUid = playerIdToUid[awayId];
        if (homeUid == null || awayUid == null) continue;
        result.add(
          GNEsportMatch(
            id: _newId(),
            homeTeamId: homeUid,
            awayTeamId: awayUid,
            homeScore: m.home!.score!,
            awayScore: m.away!.score!,
            date: _parseDate(m.created) ?? offlineLeague.dateTime,
            isFinished: true,
            leagueId: leagueId,
          ),
        );
      }
    }
    return result;
  }

  List<PlannedStatDoc> _buildStatDocs({
    required List<String> uids,
    required String leagueId,
    required List<GNEsportMatch> matches,
  }) {
    final totals = {for (final u in uids) u: _StatTotals()};
    for (final m in matches) {
      final h = m.homeScore;
      final a = m.awayScore;
      if (h == null || a == null) continue;
      totals[m.homeTeamId]?.apply(scoredFor: h, scoredAgainst: a);
      totals[m.awayTeamId]?.apply(scoredFor: a, scoredAgainst: h);
    }
    return [
      for (final u in uids)
        PlannedStatDoc(
          id: _newId(),
          userId: u,
          matchesPlayed: totals[u]!.mp,
          goals: totals[u]!.gf,
          goalsConceded: totals[u]!.ga,
          wins: totals[u]!.w,
          draws: totals[u]!.d,
          losses: totals[u]!.l,
        ),
    ];
  }

  bool _isCompleted(MatchModel m) =>
      m.status &&
      m.home != null &&
      m.away != null &&
      m.home!.score != null &&
      m.away!.score != null;

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class _StatTotals {
  int mp = 0;
  int gf = 0;
  int ga = 0;
  int w = 0;
  int d = 0;
  int l = 0;

  void apply({required int scoredFor, required int scoredAgainst}) {
    mp++;
    gf += scoredFor;
    ga += scoredAgainst;
    if (scoredFor > scoredAgainst) {
      w++;
    } else if (scoredFor == scoredAgainst) {
      d++;
    } else {
      l++;
    }
  }
}
