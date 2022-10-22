import 'package:equatable/equatable.dart';
import 'package:game_note/domain/entities/league_model.dart';
import 'package:game_note/domain/entities/player_model.dart';

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

  bool get needFloatButton => isEmpty || isLoaded;
}

class LeagueDetailState extends Equatable {
  final LeagueDetailStatus status;
  final List<PlayerModel> players;
  final bool enableConfirmSelectPlayers;
  final LeagueModel? model;

  const LeagueDetailState({
    this.status = LeagueDetailStatus.loading,
    this.model,
    this.players = const [],
    this.enableConfirmSelectPlayers = false,
  });

  LeagueDetailState copyWith({
    LeagueDetailStatus? status,
    LeagueModel? model,
    List<PlayerModel>? players,
    bool? enable,
  }) {
    return LeagueDetailState(
      status: status ?? this.status,
      model: model ?? this.model,
      players: players ?? this.players,
      enableConfirmSelectPlayers: enable ?? enableConfirmSelectPlayers,
    );
  }

  @override
  List<Object?> get props => [status, model, players];
}
