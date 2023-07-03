part of 'statistic_bloc.dart';

abstract class StatisticEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class GeneratePersonalStatisticEvent extends StatisticEvent {}
