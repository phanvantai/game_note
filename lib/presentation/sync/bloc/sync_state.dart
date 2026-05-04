part of 'sync_bloc.dart';

enum SyncStep { selectSource, mapPlayers, preview, executing }

enum SyncStatus { idle, loading, ready, running, success, error }

class SyncState extends Equatable {
  const SyncState({
    this.step = SyncStep.selectSource,
    this.status = SyncStatus.idle,
    this.offlineLeagues = const [],
    this.myGroups = const [],
    this.selectedLeague,
    this.selectedGroup,
    this.groupMembers = const [],
    this.mappings = const {},
    this.plan,
    this.progress = 0,
    this.progressLabel = '',
    this.errorMessage,
    this.createdLeagueId,
  });

  final SyncStep step;
  final SyncStatus status;
  final List<LeagueModel> offlineLeagues;
  final List<GNEsportGroup> myGroups;
  final LeagueModel? selectedLeague;
  final GNEsportGroup? selectedGroup;
  final List<GNUser> groupMembers;
  final Map<int, MappingTarget> mappings;
  final MigrationPlan? plan;
  final double progress;
  final String progressLabel;
  final String? errorMessage;
  final String? createdLeagueId;

  bool get canGoToMapping =>
      selectedLeague != null && selectedGroup != null && status != SyncStatus.loading;

  bool get canGoToPreview {
    final league = selectedLeague;
    if (league == null) return false;
    final ids = league.players
        .map((p) => p.playerModel.id)
        .whereType<int>()
        .toSet();
    if (ids.isEmpty) return false;
    if (!ids.every(mappings.containsKey)) return false;
    final uids = <String>{};
    for (final t in mappings.values) {
      if (t is MapToExisting) {
        if (!uids.add(t.uid)) return false;
      }
    }
    return true;
  }

  SyncState copyWith({
    SyncStep? step,
    SyncStatus? status,
    List<LeagueModel>? offlineLeagues,
    List<GNEsportGroup>? myGroups,
    LeagueModel? selectedLeague,
    bool clearSelectedLeague = false,
    GNEsportGroup? selectedGroup,
    bool clearSelectedGroup = false,
    List<GNUser>? groupMembers,
    Map<int, MappingTarget>? mappings,
    MigrationPlan? plan,
    bool clearPlan = false,
    double? progress,
    String? progressLabel,
    String? errorMessage,
    bool clearError = false,
    String? createdLeagueId,
  }) {
    return SyncState(
      step: step ?? this.step,
      status: status ?? this.status,
      offlineLeagues: offlineLeagues ?? this.offlineLeagues,
      myGroups: myGroups ?? this.myGroups,
      selectedLeague:
          clearSelectedLeague ? null : (selectedLeague ?? this.selectedLeague),
      selectedGroup:
          clearSelectedGroup ? null : (selectedGroup ?? this.selectedGroup),
      groupMembers: groupMembers ?? this.groupMembers,
      mappings: mappings ?? this.mappings,
      plan: clearPlan ? null : (plan ?? this.plan),
      progress: progress ?? this.progress,
      progressLabel: progressLabel ?? this.progressLabel,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createdLeagueId: createdLeagueId ?? this.createdLeagueId,
    );
  }

  @override
  List<Object?> get props => [
        step,
        status,
        offlineLeagues,
        myGroups,
        selectedLeague,
        selectedGroup,
        groupMembers,
        mappings,
        plan,
        progress,
        progressLabel,
        errorMessage,
        createdLeagueId,
      ];
}
