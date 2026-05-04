import 'package:equatable/equatable.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';

/// Pure description của những gì sẽ ghi lên Firestore. Build xong ở step
/// preview, user xác nhận rồi mới commit thành 1 batch atomic. Không có
/// I/O ở pha build — cho phép test pure và hiển thị op count cho user.
class MigrationPlan extends Equatable {
  const MigrationPlan({
    required this.placeholderUsers,
    required this.groupId,
    required this.uidsToAddToGroup,
    required this.leagueId,
    required this.leagueData,
    required this.participantUids,
    required this.statDocs,
    required this.matches,
  });

  /// Mới: id + display name. ownerId không có vì placeholder không có account
  /// — chỉ là user doc trống đại diện cho người chơi offline.
  final List<PlannedPlaceholder> placeholderUsers;

  final String groupId;

  /// uids cần arrayUnion vào group.members. Có thể overlap với members hiện
  /// tại — arrayUnion idempotent nên không sao.
  final List<String> uidsToAddToGroup;

  final String leagueId;
  final Map<String, dynamic> leagueData;

  /// uids participants của league (set trực tiếp, không arrayUnion vì league
  /// vừa tạo).
  final List<String> participantUids;

  final List<PlannedStatDoc> statDocs;
  final List<GNEsportMatch> matches;

  /// Tổng số write ops sẽ commit lên Firestore. Dùng để:
  /// 1) hiện cho user ở step preview ("Sẽ tạo X bản ghi");
  /// 2) check giới hạn 500 ops/batch.
  int get totalOps =>
      placeholderUsers.length + // 1 set / placeholder
      (uidsToAddToGroup.isEmpty ? 0 : 1) + // 1 update group
      1 + // create league
      statDocs.length + // 1 set / stat doc (1 doc / participant)
      matches.length; // 1 set / match

  static const int batchLimit = 500;
  bool get exceedsBatchLimit => totalOps > batchLimit;

  @override
  List<Object?> get props => [
        placeholderUsers,
        groupId,
        uidsToAddToGroup,
        leagueId,
        leagueData,
        participantUids,
        statDocs,
        matches,
      ];
}

class PlannedPlaceholder extends Equatable {
  const PlannedPlaceholder({required this.id, required this.displayName});
  final String id;
  final String displayName;

  @override
  List<Object?> get props => [id, displayName];
}

/// Stat doc với số liệu đã tính sẵn từ matches (client-side reconcile).
class PlannedStatDoc extends Equatable {
  const PlannedStatDoc({
    required this.id,
    required this.userId,
    required this.matchesPlayed,
    required this.goals,
    required this.goalsConceded,
    required this.wins,
    required this.draws,
    required this.losses,
  });

  final String id;
  final String userId;
  final int matchesPlayed;
  final int goals;
  final int goalsConceded;
  final int wins;
  final int draws;
  final int losses;

  @override
  List<Object?> get props => [
        id,
        userId,
        matchesPlayed,
        goals,
        goalsConceded,
        wins,
        draws,
        losses,
      ];
}

class PlanTooLargeException implements Exception {
  PlanTooLargeException(this.totalOps);
  final int totalOps;

  @override
  String toString() =>
      'PlanTooLargeException: $totalOps ops > ${MigrationPlan.batchLimit}';
}
