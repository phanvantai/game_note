part of 'statistic_bloc.dart';

class StatisticState extends Equatable {
  final ViewStatus viewStatus;
  final List<PersonalStatistic> listStatistic;

  const StatisticState({
    this.viewStatus = ViewStatus.initial,
    this.listStatistic = const [],
  });

  StatisticState copyWith({
    ViewStatus? viewStatus,
    List<PersonalStatistic>? listStatistic,
  }) {
    return StatisticState(
      viewStatus: viewStatus ?? this.viewStatus,
      listStatistic: listStatistic ?? this.listStatistic,
    );
  }

  @override
  List<Object?> get props => [
        viewStatus,
        listStatistic,
      ];
}
