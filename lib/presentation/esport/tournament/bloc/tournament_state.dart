part of 'tournament_bloc.dart';

class TournamentState extends Equatable {
  static const Object _otherCursorUnchanged = Object();

  /// Loading status for the "Giải đấu của tôi" tab.
  final ViewStatus myStatus;

  /// Loading status for the "Giải đấu khác" tab. Also reflects load-more.
  final ViewStatus otherStatus;

  final List<GNEsportLeague> myLeagues;
  final List<GNEsportLeague> otherLeagues;

  /// Cursor for the next page of `otherLeagues`. Opaque `DocumentSnapshot` —
  /// stored as `Object?` so the bloc layer doesn't import cloud_firestore.
  final Object? otherCursor;
  final bool otherHasMore;

  final String errorMessage;

  /// Bumped whenever a pull-to-refresh finishes, even if the fetched data is
  /// identical to the current state. This lets `RefreshIndicator` stop
  /// reliably on no-op refreshes.
  final int refreshTick;

  const TournamentState({
    this.myStatus = ViewStatus.initial,
    this.otherStatus = ViewStatus.initial,
    this.myLeagues = const [],
    this.otherLeagues = const [],
    this.otherCursor,
    this.otherHasMore = true,
    this.errorMessage = '',
    this.refreshTick = 0,
  });

  TournamentState copyWith({
    ViewStatus? myStatus,
    ViewStatus? otherStatus,
    List<GNEsportLeague>? myLeagues,
    List<GNEsportLeague>? otherLeagues,
    Object? otherCursor = _otherCursorUnchanged,
    bool? otherHasMore,
    String? errorMessage,
    int? refreshTick,
  }) {
    return TournamentState(
      myStatus: myStatus ?? this.myStatus,
      otherStatus: otherStatus ?? this.otherStatus,
      myLeagues: myLeagues ?? this.myLeagues,
      otherLeagues: otherLeagues ?? this.otherLeagues,
      otherCursor: identical(otherCursor, _otherCursorUnchanged)
          ? this.otherCursor
          : otherCursor,
      otherHasMore: otherHasMore ?? this.otherHasMore,
      errorMessage: errorMessage ?? this.errorMessage,
      refreshTick: refreshTick ?? this.refreshTick,
    );
  }

  @override
  List<Object?> get props => [
        myStatus,
        otherStatus,
        myLeagues,
        otherLeagues,
        otherCursor,
        otherHasMore,
        errorMessage,
        refreshTick,
      ];
}
