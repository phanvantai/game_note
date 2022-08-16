import 'package:equatable/equatable.dart';
import 'package:game_note/domain/entities/result_model.dart';

class MatchModel extends Equatable {
  // status: finished: true, not finished: false
  final bool status;
  final ResultModel home;
  final ResultModel away;
  final DateTime created = DateTime.now();

  MatchModel({required this.home, required this.away, this.status = false});

  @override
  List<Object?> get props => [home, away, created, status];
}
