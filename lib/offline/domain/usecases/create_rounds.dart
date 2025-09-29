import 'package:dartz/dartz.dart';
import 'package:pes_arena/core/common/failure.dart';
import 'package:pes_arena/core/usecase/usecase.dart';
import 'package:pes_arena/offline/domain/entities/league_model.dart';
import 'package:pes_arena/offline/domain/repositories/league_repository.dart';

class CreateRounds implements UseCase<LeagueModel, CreateRoundsParams> {
  final LeagueRepository repository;

  CreateRounds(this.repository);
  @override
  Future<Either<Failure, LeagueModel>> call(CreateRoundsParams params) {
    return repository.createRounds(params);
  }
}
