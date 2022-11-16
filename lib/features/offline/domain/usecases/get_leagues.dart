import 'package:dartz/dartz.dart';
import 'package:game_note/core/error/failure.dart';
import 'package:game_note/core/usecase/usecase.dart';
import 'package:game_note/features/offline/domain/entities/league_model.dart';
import 'package:game_note/features/offline/domain/repositories/league_repository.dart';

class GetLeagues implements UseCase<List<LeagueModel>, GetLeaguesParams> {
  final LeagueRepository repository;

  GetLeagues(this.repository);
  @override
  Future<Either<Failure, List<LeagueModel>>> call(GetLeaguesParams params) {
    return repository.getLeagues(params);
  }
}
