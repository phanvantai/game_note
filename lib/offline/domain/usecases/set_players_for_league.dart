import 'package:dartz/dartz.dart';
import 'package:game_note/core/common/failure.dart';
import 'package:game_note/core/usecase/usecase.dart';
import 'package:game_note/offline/domain/entities/league_model.dart';
import 'package:game_note/offline/domain/repositories/league_repository.dart';

class SetPlayersForLeague
    implements UseCase<LeagueModel, SetPlayersForLeagueParams> {
  final LeagueRepository repository;

  SetPlayersForLeague(this.repository);
  @override
  Future<Either<Failure, LeagueModel>> call(SetPlayersForLeagueParams params) {
    return repository.setPlayersForLeague(params);
  }
}
