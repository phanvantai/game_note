part of 'tournament_detail_bloc.dart';

class TournamentDetailState extends Equatable {
  final ViewStatus viewStatus;
  final GNEsportLeague? league;
  final List<GNEsportLeagueStat> participants;
  final List<GNEsportMatch> matches;
  final List<GNUser> users;
  final String errorMessage;

  /// Bumped every time `GetParticipantsAndMatches` finishes (success OR
  /// failure). Lets pull-to-refresh detect completion even when the new
  /// data equals the old data — without it Equatable suppresses the emit
  /// and the RefreshIndicator spins forever.
  final int refreshTick;
  // full mode: which group tab is currently selected (null = no selection)
  final String? selectedGroupId;

  const TournamentDetailState({
    this.viewStatus = ViewStatus.initial,
    this.league,
    this.participants = const [],
    this.matches = const [],
    this.errorMessage = '',
    this.users = const [],
    this.refreshTick = 0,
    this.selectedGroupId,
  });

  TournamentDetailState copyWith({
    ViewStatus? viewStatus,
    GNEsportLeague? league,
    List<GNEsportLeagueStat>? participants,
    List<GNEsportMatch>? matches,
    String? errorMessage,
    List<GNUser>? users,
    int? refreshTick,
    String? selectedGroupId,
    bool clearSelectedGroupId = false,
  }) {
    return TournamentDetailState(
      viewStatus: viewStatus ?? this.viewStatus,
      league: league ?? this.league,
      participants: participants ?? this.participants,
      matches: matches ?? this.matches,
      errorMessage: errorMessage ?? this.errorMessage,
      users: users ?? this.users,
      refreshTick: refreshTick ?? this.refreshTick,
      selectedGroupId: clearSelectedGroupId
          ? null
          : (selectedGroupId ?? this.selectedGroupId),
    );
  }

  @override
  List<Object?> get props => [
        viewStatus,
        league,
        participants,
        matches,
        errorMessage,
        users,
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
    return matches.where((m) => m.phase == 'group' && m.groupId == groupId).toList();
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
