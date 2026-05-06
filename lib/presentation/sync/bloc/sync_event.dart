part of 'sync_bloc.dart';

sealed class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class SyncLoadInitialData extends SyncEvent {
  const SyncLoadInitialData();
}

class SyncSelectOfflineLeague extends SyncEvent {
  const SyncSelectOfflineLeague(this.leagueId);
  final int leagueId;

  @override
  List<Object?> get props => [leagueId];
}

class SyncSelectGroup extends SyncEvent {
  const SyncSelectGroup(this.groupId);
  final String groupId;

  @override
  List<Object?> get props => [groupId];
}

class SyncSetMapping extends SyncEvent {
  const SyncSetMapping({required this.playerId, required this.target});
  final int playerId;
  final MappingTarget target;

  @override
  List<Object?> get props => [playerId, target];
}

class SyncClearMapping extends SyncEvent {
  const SyncClearMapping(this.playerId);
  final int playerId;

  @override
  List<Object?> get props => [playerId];
}

class SyncGoToStep extends SyncEvent {
  const SyncGoToStep(this.step);
  final SyncStep step;

  @override
  List<Object?> get props => [step];
}

class SyncRun extends SyncEvent {
  const SyncRun();
}
