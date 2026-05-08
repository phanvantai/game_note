part of 'tournament_bloc.dart';

abstract class TournamentEvent extends Equatable {
  const TournamentEvent();

  @override
  List<Object?> get props => [];
}

/// Initial / refresh load of the "Tham gia" tab.
class LoadMyLeagues extends TournamentEvent {}

/// Append the next page to the "Tham gia" tab.
class LoadMoreMyLeagues extends TournamentEvent {}

/// Initial / refresh load of the "Quản lý" tab.
class LoadManagedLeagues extends TournamentEvent {}

/// Append the next page to the "Quản lý" tab.
class LoadMoreManagedLeagues extends TournamentEvent {}

/// Initial load of the "Khác" tab (resets pagination cursor).
class LoadOtherLeagues extends TournamentEvent {}

/// Append the next page to the "Khác" tab.
class LoadMoreOtherLeagues extends TournamentEvent {}

/// Pull-to-refresh: reload both tabs in parallel and reset cursor.
class RefreshTournaments extends TournamentEvent {}

