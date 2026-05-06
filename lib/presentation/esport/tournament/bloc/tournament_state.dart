part of 'tournament_bloc.dart';

class TournamentState extends Equatable {
  static const Object _sentinel = Object();

  /// Loading status for the "Tham gia" tab.
  final ViewStatus myStatus;

  /// Loading status for the "Quản lý" tab.
  final ViewStatus managedStatus;

  /// Loading status for the "Khác" tab. Also reflects load-more.
  final ViewStatus otherStatus;

  final List<GNEsportLeague> myLeagues;
  final List<GNEsportLeague> managedLeagues;
  final List<GNEsportLeague> otherLeagues;

  /// Cursors for next-page fetches. Stored as `Object?` so the bloc layer
  /// doesn't import cloud_firestore directly.
  final Object? myCursor;
  final bool myHasMore;
  final Object? managedCursor;
  final bool managedHasMore;
  final Object? otherCursor;
  final bool otherHasMore;

  final String errorMessage;

  /// Bumped whenever a pull-to-refresh finishes, even if the fetched data is
  /// identical to the current state. This lets `RefreshIndicator` stop
  /// reliably on no-op refreshes.
  final int refreshTick;

  const TournamentState({
    this.myStatus = ViewStatus.initial,
    this.managedStatus = ViewStatus.initial,
    this.otherStatus = ViewStatus.initial,
    this.myLeagues = const [],
    this.managedLeagues = const [],
    this.otherLeagues = const [],
    this.myCursor,
    this.myHasMore = true,
    this.managedCursor,
    this.managedHasMore = true,
    this.otherCursor,
    this.otherHasMore = true,
    this.errorMessage = '',
    this.refreshTick = 0,
  });

  TournamentState copyWith({
    ViewStatus? myStatus,
    ViewStatus? managedStatus,
    ViewStatus? otherStatus,
    List<GNEsportLeague>? myLeagues,
    List<GNEsportLeague>? managedLeagues,
    List<GNEsportLeague>? otherLeagues,
    Object? myCursor = _sentinel,
    bool? myHasMore,
    Object? managedCursor = _sentinel,
    bool? managedHasMore,
    Object? otherCursor = _sentinel,
    bool? otherHasMore,
    String? errorMessage,
    int? refreshTick,
  }) {
    return TournamentState(
      myStatus: myStatus ?? this.myStatus,
      managedStatus: managedStatus ?? this.managedStatus,
      otherStatus: otherStatus ?? this.otherStatus,
      myLeagues: myLeagues ?? this.myLeagues,
      managedLeagues: managedLeagues ?? this.managedLeagues,
      otherLeagues: otherLeagues ?? this.otherLeagues,
      myCursor: identical(myCursor, _sentinel) ? this.myCursor : myCursor,
      myHasMore: myHasMore ?? this.myHasMore,
      managedCursor: identical(managedCursor, _sentinel)
          ? this.managedCursor
          : managedCursor,
      managedHasMore: managedHasMore ?? this.managedHasMore,
      otherCursor:
          identical(otherCursor, _sentinel) ? this.otherCursor : otherCursor,
      otherHasMore: otherHasMore ?? this.otherHasMore,
      errorMessage: errorMessage ?? this.errorMessage,
      refreshTick: refreshTick ?? this.refreshTick,
    );
  }

  @override
  List<Object?> get props => [
        myStatus,
        managedStatus,
        otherStatus,
        myLeagues,
        managedLeagues,
        otherLeagues,
        myCursor,
        myHasMore,
        managedCursor,
        managedHasMore,
        otherCursor,
        otherHasMore,
        errorMessage,
        refreshTick,
      ];
}
