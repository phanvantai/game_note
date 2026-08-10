part of 'tournament_detail_bloc.dart';

enum TournamentDetailSlice { league, stats, matches }

enum DetailSliceStatus { waiting, ready, failed }

enum DetailBootstrapStatus { loading, ready, failure }

class TournamentDetailState extends Equatable {
  final ViewStatus viewStatus;
  final DetailSliceStatus leagueSliceStatus;
  final DetailSliceStatus statsSliceStatus;
  final DetailSliceStatus matchesSliceStatus;
  final GNEsportLeague? league;
  final List<GNEsportLeagueStat> participants;
  final List<GNEsportMatch> matches;
  final Map<String, GNUser> usersById;
  final Set<String> pendingMatchIds;
  final Map<String, String> matchErrorsById;
  final Map<TournamentDetailSlice, String> streamErrors;
  final bool leagueDeleted;
  final String errorMessage;

  /// Bumped when `EnsureDetailSubscriptions` finishes its subscription
  /// health check. Lets pull-to-refresh detect completion even when no
  /// detail data changed — otherwise Equatable suppresses the emit and the
  /// RefreshIndicator spins forever.
  final int refreshTick;
  // full mode: which group tab is currently selected (null = no selection)
  final String? selectedGroupId;

  const TournamentDetailState({
    this.viewStatus = ViewStatus.initial,
    this.leagueSliceStatus = DetailSliceStatus.waiting,
    this.statsSliceStatus = DetailSliceStatus.waiting,
    this.matchesSliceStatus = DetailSliceStatus.waiting,
    this.league,
    this.participants = const [],
    this.matches = const [],
    this.errorMessage = '',
    this.usersById = const {},
    this.pendingMatchIds = const {},
    this.matchErrorsById = const {},
    this.streamErrors = const {},
    this.leagueDeleted = false,
    this.refreshTick = 0,
    this.selectedGroupId,
  });

  List<GNUser> get users => usersById.values.toList(growable: false);

  DetailBootstrapStatus get bootstrapStatus {
    if (leagueDeleted ||
        (league == null && leagueSliceStatus == DetailSliceStatus.failed)) {
      return DetailBootstrapStatus.failure;
    }

    if (league != null &&
        statsSliceStatus != DetailSliceStatus.waiting &&
        matchesSliceStatus != DetailSliceStatus.waiting) {
      return DetailBootstrapStatus.ready;
    }

    return DetailBootstrapStatus.loading;
  }

  TournamentDetailState copyWith({
    ViewStatus? viewStatus,
    DetailSliceStatus? leagueSliceStatus,
    DetailSliceStatus? statsSliceStatus,
    DetailSliceStatus? matchesSliceStatus,
    GNEsportLeague? league,
    List<GNEsportLeagueStat>? participants,
    List<GNEsportMatch>? matches,
    String? errorMessage,
    Map<String, GNUser>? usersById,
    Set<String>? pendingMatchIds,
    Map<String, String>? matchErrorsById,
    Map<TournamentDetailSlice, String>? streamErrors,
    bool? leagueDeleted,
    // Temporary compatibility for callers migrating to the keyed cache.
    List<GNUser>? users,
    int? refreshTick,
    String? selectedGroupId,
    bool clearLeague = false,
    bool clearSelectedGroupId = false,
  }) {
    final nextUsersById =
        usersById ??
        (users == null
            ? this.usersById
            : {for (final user in users) user.id: user});

    return TournamentDetailState(
      viewStatus: viewStatus ?? this.viewStatus,
      leagueSliceStatus: leagueSliceStatus ?? this.leagueSliceStatus,
      statsSliceStatus: statsSliceStatus ?? this.statsSliceStatus,
      matchesSliceStatus: matchesSliceStatus ?? this.matchesSliceStatus,
      league: clearLeague ? null : (league ?? this.league),
      participants: List.unmodifiable(participants ?? this.participants),
      matches: List.unmodifiable(matches ?? this.matches),
      errorMessage: errorMessage ?? this.errorMessage,
      usersById: Map.unmodifiable(nextUsersById),
      pendingMatchIds: Set.unmodifiable(
        pendingMatchIds ?? this.pendingMatchIds,
      ),
      matchErrorsById: Map.unmodifiable(
        matchErrorsById ?? this.matchErrorsById,
      ),
      streamErrors: Map.unmodifiable(streamErrors ?? this.streamErrors),
      leagueDeleted: leagueDeleted ?? this.leagueDeleted,
      refreshTick: refreshTick ?? this.refreshTick,
      selectedGroupId: clearSelectedGroupId
          ? null
          : (selectedGroupId ?? this.selectedGroupId),
    );
  }

  @override
  List<Object?> get props => [
    viewStatus,
    leagueSliceStatus,
    statsSliceStatus,
    matchesSliceStatus,
    league,
    participants,
    matches,
    errorMessage,
    usersById,
    pendingMatchIds,
    matchErrorsById,
    streamErrors,
    leagueDeleted,
    refreshTick,
    selectedGroupId,
  ];

  bool get currentUserIsMember {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;
      return (league?.group?.members ?? <String>[]).any((e) => e == uid);
    } catch (_) {
      return false;
    }
  }

  bool get currentUserIsLeagueAdmin {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return false;
      if (currentUid == league?.group?.ownerId) return true;
      return league?.ownerId == currentUid;
    } catch (_) {
      return false;
    }
  }

  List<GNEsportMatch> get fixtures {
    return matches
        .where((m) => !m.isFinished && m.phase != 'knockout')
        .toList();
  }

  List<GNEsportMatch> get results {
    return matches.where((element) => element.isFinished).toList();
  }

  List<GNEsportMatch> get knockoutMatches {
    return matches.where((m) => m.phase == 'knockout').toList();
  }

  List<GNEsportMatch> groupMatches(String groupId) {
    return matches
        .where((m) => m.phase == 'group' && m.groupId == groupId)
        .toList();
  }

  List<GNEsportLeagueStat> groupStats(String groupId) {
    return participants.where((s) => s.groupId == groupId).toList();
  }

  List<String> get groupIds {
    final ids = <String>{};
    for (final m in matches) {
      if (m.phase == 'group' && m.groupId != null) ids.add(m.groupId!);
    }
    final sorted = ids.toList()..sort();
    return sorted;
  }

  bool get allGroupMatchesFinished {
    final groupMatches = matches.where((m) => m.phase == 'group').toList();
    if (groupMatches.isEmpty) return false;
    return groupMatches.every((m) => m.isFinished);
  }
}
