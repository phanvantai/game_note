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

class AddTournament extends TournamentEvent {
  final String name;
  final String groupId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String description;
  final bool rankPayoutEnabled;
  final List<int> rankPayouts;
  final int defaultMatchCost;

  const AddTournament({
    required this.name,
    required this.groupId,
    this.startDate,
    this.endDate,
    this.description = '',
    this.rankPayoutEnabled = false,
    this.rankPayouts = const [],
    this.defaultMatchCost = 50000,
  });

  @override
  List<Object?> get props => [
        name,
        groupId,
        startDate,
        endDate,
        description,
        rankPayoutEnabled,
        rankPayouts,
        defaultMatchCost,
      ];
}
