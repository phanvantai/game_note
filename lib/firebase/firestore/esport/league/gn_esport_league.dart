import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../group/gn_esport_group.dart';

enum GNEsportLeagueStatus { upcoming, ongoing, finished }

enum TournamentMode { league, cup, full }

extension TournamentModeExtension on TournamentMode {
  String get value {
    switch (this) {
      case TournamentMode.league:
        return 'league';
      case TournamentMode.cup:
        return 'cup';
      case TournamentMode.full:
        return 'full';
    }
  }

  static TournamentMode fromString(String? value) {
    switch (value) {
      case 'cup':
        return TournamentMode.cup;
      case 'full':
        return TournamentMode.full;
      default:
        return TournamentMode.league;
    }
  }
}

extension GNEsportLeagueStatusExtension on GNEsportLeagueStatus {
  String get value {
    switch (this) {
      case GNEsportLeagueStatus.upcoming:
        return 'upcoming';
      case GNEsportLeagueStatus.ongoing:
        return 'ongoing';
      case GNEsportLeagueStatus.finished:
        return 'finished';
    }
  }

  String get name {
    switch (this) {
      case GNEsportLeagueStatus.upcoming:
        return 'Sắp diễn ra';
      case GNEsportLeagueStatus.ongoing:
        return 'Đang diễn ra';
      case GNEsportLeagueStatus.finished:
        return 'Đã kết thúc';
    }
  }

  Color get color {
    switch (this) {
      case GNEsportLeagueStatus.upcoming:
        return Colors.green[300]!;
      case GNEsportLeagueStatus.ongoing:
        return Colors.orange[300]!;
      case GNEsportLeagueStatus.finished:
        return Colors.red[300]!;
    }
  }

  static GNEsportLeagueStatus fromString(String? status) {
    switch (status) {
      case 'upcoming':
        return GNEsportLeagueStatus.upcoming;
      case 'ongoing':
        return GNEsportLeagueStatus.ongoing;
      case 'finished':
        return GNEsportLeagueStatus.finished;
      default:
        return GNEsportLeagueStatus.upcoming;
    }
  }
}

class GNEsportLeague extends Equatable {
  final String id; // league id
  final String ownerId; // owner id of the league
  final String groupId; // id of the group this league belongs to
  final String name; // league name
  final DateTime startDate; // start date of the league
  final DateTime? endDate; // end date of the league (nullable)
  final bool isActive; // whether the league is active or not
  final String description; // league description
  final List<String> participants; // list of participants
  final String? status; // status of the league: upcoming, ongoing, finished

  // Cost split config (chi phí tiền máy/ăn uống giữa người chơi).
  // Tracker only — app does not handle payments.
  final bool rankPayoutEnabled;
  final List<int> rankPayouts; // index 0 = số tiền hạng 2 trả cho hạng 1, ...
  // Số tiền prefill cho ô "Tiền trận này" khi user bật cost cho 1 trận.
  // Không phải toggle bật/tắt feature — per-match cost luôn có thể bật từng trận.
  final int defaultMatchCost;

  /// Admin đã xác nhận không còn cần merge/replace user nào nữa trong giải này.
  final bool mergeCompleted;

  final TournamentMode mode;
  // full mode: số bảng (1, 2, 4...)
  final int groupCount;
  // full mode: số người mỗi bảng lên knockout
  final int advanceCount;

  final GNEsportGroup? group; // group this league belongs to

  // esport_leagues is a top-level collection
  // esports_leagues/{leagueId}
  static const String collectionName = 'esports_leagues';

  static const String fieldId = 'id';
  static const String fieldOwnerId = 'ownerId';
  static const String fieldGroupId = 'groupId';
  static const String fieldName = 'name';
  static const String fieldStartDate = 'startDate';
  static const String fieldEndDate = 'endDate';
  static const String fieldIsActive = 'isActive';
  static const String fieldDescription = 'description';
  static const String fieldParticipants = 'participants';
  static const String fieldStatus = 'status';
  static const String fieldRankPayoutEnabled = 'rankPayoutEnabled';
  static const String fieldRankPayouts = 'rankPayouts';
  static const String fieldDefaultMatchCost = 'defaultMatchCost';
  static const String fieldMergeCompleted = 'mergeCompleted';
  static const String fieldMode = 'mode';
  static const String fieldGroupCount = 'groupCount';
  static const String fieldAdvanceCount = 'advanceCount';
  static const String fieldKnockoutSeeding = 'knockoutSeeding';

  /// Seeding for knockout bracket:
  /// - League: `[]`
  /// - Cup: ordered user IDs (seed 1 first)
  /// - Full: position strings like `["A1","B1","A2","B2"]`
  final List<String> knockoutSeeding;

  const GNEsportLeague({
    required this.id,
    required this.ownerId,
    required this.groupId,
    required this.name,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.description,
    required this.participants,
    this.group,
    this.status,
    this.rankPayoutEnabled = false,
    this.rankPayouts = const [],
    this.defaultMatchCost = 50000,
    this.mergeCompleted = false,
    this.mode = TournamentMode.league,
    this.groupCount = 1,
    this.advanceCount = 2,
    this.knockoutSeeding = const [],
  });

  @override
  List<Object?> get props => [
        id,
        ownerId,
        groupId,
        name,
        startDate,
        endDate,
        isActive,
        description,
        participants,
        status,
        group,
        rankPayoutEnabled,
        rankPayouts,
        defaultMatchCost,
        mergeCompleted,
        mode,
        groupCount,
        advanceCount,
        knockoutSeeding,
      ];

  GNEsportLeague copyWith({
    String? id,
    String? ownerId,
    String? groupId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? description,
    List<String>? participants,
    GNEsportGroup? group,
    String? status,
    bool? rankPayoutEnabled,
    List<int>? rankPayouts,
    int? defaultMatchCost,
    bool? mergeCompleted,
    TournamentMode? mode,
    int? groupCount,
    int? advanceCount,
    List<String>? knockoutSeeding,
  }) {
    return GNEsportLeague(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      participants: participants ?? this.participants,
      group: group ?? this.group,
      status: status ?? this.status,
      rankPayoutEnabled: rankPayoutEnabled ?? this.rankPayoutEnabled,
      rankPayouts: rankPayouts ?? this.rankPayouts,
      defaultMatchCost: defaultMatchCost ?? this.defaultMatchCost,
      mergeCompleted: mergeCompleted ?? this.mergeCompleted,
      mode: mode ?? this.mode,
      groupCount: groupCount ?? this.groupCount,
      advanceCount: advanceCount ?? this.advanceCount,
      knockoutSeeding: knockoutSeeding ?? this.knockoutSeeding,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      fieldGroupId: groupId,
      fieldOwnerId: ownerId,
      fieldName: name,
      fieldStartDate: Timestamp.fromDate(startDate),
      if (endDate != null) fieldEndDate: Timestamp.fromDate(endDate!),
      fieldIsActive: isActive,
      fieldDescription: description,
      fieldParticipants: participants,
      fieldStatus: status,
      fieldRankPayoutEnabled: rankPayoutEnabled,
      fieldRankPayouts: rankPayouts,
      fieldDefaultMatchCost: defaultMatchCost,
      fieldMergeCompleted: mergeCompleted,
      fieldMode: mode.value,
      fieldGroupCount: groupCount,
      fieldAdvanceCount: advanceCount,
      if (knockoutSeeding.isNotEmpty) fieldKnockoutSeeding: knockoutSeeding,
    };
  }

  factory GNEsportLeague.fromFirestore(DocumentSnapshot doc) {
    return GNEsportLeague.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Pure factory cho test — không cần `DocumentSnapshot`.
  /// `startDate`/`endDate` chấp nhận Firestore `Timestamp` hoặc `DateTime`.
  factory GNEsportLeague.fromMap(Map<String, dynamic> data, String id) {
    DateTime? toDate(Object? v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is Timestamp) return v.toDate();
      return null;
    }

    return GNEsportLeague(
      id: id,
      ownerId: data[fieldOwnerId] ?? '',
      groupId: data[fieldGroupId],
      name: data[fieldName],
      startDate: toDate(data[fieldStartDate]) ?? DateTime.now(),
      endDate: toDate(data[fieldEndDate]),
      isActive: data[fieldIsActive] ?? true,
      description: data[fieldDescription],
      participants: List<String>.from(data[fieldParticipants] ?? []),
      status: data[fieldStatus] ?? 'upcoming',
      rankPayoutEnabled: data[fieldRankPayoutEnabled] ?? false,
      rankPayouts: List<int>.from(
        (data[fieldRankPayouts] as List?)?.map((e) => (e as num).toInt()) ??
            const [],
      ),
      defaultMatchCost: (data[fieldDefaultMatchCost] as num?)?.toInt() ?? 50000,
      mergeCompleted: data[fieldMergeCompleted] ?? false,
      mode: TournamentModeExtension.fromString(data[fieldMode] as String?),
      groupCount: (data[fieldGroupCount] as num?)?.toInt() ?? 1,
      advanceCount: (data[fieldAdvanceCount] as num?)?.toInt() ?? 2,
      knockoutSeeding: List<String>.from(data[fieldKnockoutSeeding] ?? []),
    );
  }
}
