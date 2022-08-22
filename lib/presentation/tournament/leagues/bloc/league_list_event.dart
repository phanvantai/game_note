import 'package:equatable/equatable.dart';

class LeagueListEvent extends Equatable {
  const LeagueListEvent();
  @override
  List<Object?> get props => [];
}

class LeagueListStarted extends LeagueListEvent {}

class LeagueListCreateNewOne extends LeagueListEvent {}
