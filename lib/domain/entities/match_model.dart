import 'package:equatable/equatable.dart';
import 'package:game_note/domain/entities/result_model.dart';

class MatchModel extends Equatable {
  final ResultModel home;
  final ResultModel away;
  final DateTime created = DateTime.now();

  MatchModel({required this.home, required this.away});

  @override
  List<Object?> get props => [];
}
