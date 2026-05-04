part of 'dashboard_bloc.dart';

class DashboardState extends Equatable {
  static const Object _statsUnchanged = Object();

  final ViewStatus viewStatus;
  final DashboardStats? stats;
  final String errorMessage;

  const DashboardState({
    this.viewStatus = ViewStatus.initial,
    this.stats,
    this.errorMessage = '',
  });

  DashboardState copyWith({
    ViewStatus? viewStatus,
    Object? stats = _statsUnchanged,
    String? errorMessage,
  }) {
    return DashboardState(
      viewStatus: viewStatus ?? this.viewStatus,
      stats: identical(stats, _statsUnchanged)
          ? this.stats
          : stats as DashboardStats?,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [viewStatus, stats, errorMessage];
}
