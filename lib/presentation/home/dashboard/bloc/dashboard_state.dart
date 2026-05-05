part of 'dashboard_bloc.dart';

class DashboardState extends Equatable {
  static const Object _statsUnchanged = Object();

  final ViewStatus viewStatus;
  final DashboardStats? stats;
  final String errorMessage;

  /// True when [stats] came from local cache and a fresh fetch is in flight.
  /// Used by the UI to show a subtle refresh indicator without hiding the
  /// already-rendered numbers.
  final bool isStale;

  const DashboardState({
    this.viewStatus = ViewStatus.initial,
    this.stats,
    this.errorMessage = '',
    this.isStale = false,
  });

  DashboardState copyWith({
    ViewStatus? viewStatus,
    Object? stats = _statsUnchanged,
    String? errorMessage,
    bool? isStale,
  }) {
    return DashboardState(
      viewStatus: viewStatus ?? this.viewStatus,
      stats: identical(stats, _statsUnchanged)
          ? this.stats
          : stats as DashboardStats?,
      errorMessage: errorMessage ?? this.errorMessage,
      isStale: isStale ?? this.isStale,
    );
  }

  @override
  List<Object?> get props => [viewStatus, stats, errorMessage, isStale];
}
