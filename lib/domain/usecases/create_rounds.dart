import 'package:dartz/dartz.dart';
import 'package:game_note/core/error/failure.dart';
import 'package:game_note/core/usecase/usecase.dart';
import 'package:game_note/domain/entities/league_model.dart';
import 'package:game_note/domain/repositories/league_repository.dart';

class CreateRounds implements UseCase<LeagueModel, CreateRoundsParams> {
  final LeagueRepository repository;

  CreateRounds(this.repository);
  @override
  Future<Either<Failure, LeagueModel>> call(CreateRoundsParams params) {
    return repository.createRounds(params);
  }
}
