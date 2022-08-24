import 'package:equatable/equatable.dart';
import 'package:game_note/domain/entities/league_model.dart';

enum LeagueDetailStatus {
  error,
  loading,
  empty,
  addingPlayer,
  loaded,
  updating
}

extension LeagueDetailStatusX on LeagueDetailStatus {
  bool get isError => this == LeagueDetailStatus.error;
  bool get isLoading => this == LeagueDetailStatus.loading;
  bool get isEmpty => this == LeagueDetailStatus.empty;
  bool get isAddingPlayer => this == LeagueDetailStatus.addingPlayer;
  bool get isLoaded => this == LeagueDetailStatus.loaded;
  bool get isUpdating => this == LeagueDetailStatus.updating;
}

class LeagueDetailState extends Equatable {
  final LeagueDetailStatus status;
  final LeagueModel? model;

  const LeagueDetailState({
    this.status = LeagueDetailStatus.loading,
    this.model,
  });

  LeagueDetailState copyWith({
    LeagueDetailStatus? status,
    LeagueModel? model,
  }) {
    return LeagueDetailState(
      status: status ?? this.status,
      model: model ?? this.model,
    );
  }

  @override
  List<Object?> get props => [status, model];
}
