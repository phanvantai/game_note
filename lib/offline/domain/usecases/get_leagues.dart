import 'package:dartz/dartz.dart';
import 'package:pes_arena/core/common/failure.dart';
import 'package:pes_arena/core/usecase/usecase.dart';
import 'package:pes_arena/offline/domain/entities/league_model.dart';
import 'package:pes_arena/offline/domain/repositories/league_repository.dart';

class GetLeagues implements UseCase<List<LeagueModel>, GetLeaguesParams> {
  final LeagueRepository repository;

  GetLeagues(this.repository);
  @override
  Future<Either<Failure, List<LeagueModel>>> call(GetLeaguesParams params) {
    return repository.getLeagues(params);
  }
}
