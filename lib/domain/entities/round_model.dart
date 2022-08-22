import 'package:equatable/equatable.dart';
import 'package:game_note/domain/entities/match_model.dart';

class RoundModel extends Equatable {
  final int id;
  final List<MatchModel> matches;

  const RoundModel({
    required this.id,
    required this.matches,
  });
  @override
  List<Object?> get props => [id, matches];
}
