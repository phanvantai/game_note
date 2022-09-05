import 'package:dartz/dartz.dart';
import 'package:game_note/core/error/failure.dart';
import 'package:game_note/core/usecase/usecase.dart';
import 'package:game_note/domain/entities/league_model.dart';
import 'package:game_note/domain/repositories/league_repository.dart';

class GetLeague extends UseCase<LeagueModel, GetLeagueParams> {
  final LeagueRepository repository;

  GetLeague(this.repository);
  @override
  Future<Either<Failure, LeagueModel>> call(GetLeagueParams params) {
    return repository.getLeague(params);
  }
}
