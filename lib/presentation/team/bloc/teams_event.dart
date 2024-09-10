part of 'teams_bloc.dart';

abstract class TeamsEvent extends Equatable {
  const TeamsEvent();

  @override
  List<Object> get props => [];
}

class GetMyTeams extends TeamsEvent {}

class GetOtherTeams extends TeamsEvent {}
