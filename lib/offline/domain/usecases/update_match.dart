import 'package:game_note/core/common/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:game_note/core/usecase/usecase.dart';
import 'package:game_note/offline/domain/entities/league_model.dart';
import 'package:game_note/offline/domain/repositories/league_repository.dart';

class UpdateMatch implements UseCase<LeagueModel, UpdateMatchParams> {
  final LeagueRepository repository;

  UpdateMatch(this.repository);
  @override
  Future<Either<Failure, LeagueModel>> call(UpdateMatchParams params) {
    return repository.updateMatch(params);
  }
}
