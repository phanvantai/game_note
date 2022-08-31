import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:game_note/core/error/failure.dart';
import 'package:game_note/core/usecase/usecase.dart';
import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/domain/repositories/match_repository.dart';

class CreateMatch extends UseCase<MatchModel, CreateMatchParams> {
  final MatchRepository repository;

  CreateMatch(this.repository);
  @override
  Future<Either<Failure, MatchModel>> call(CreateMatchParams params) {
    return repository.createMatch(params.model);
  }
}

class CreateMatchParams extends Equatable {
  final MatchModel model;

  const CreateMatchParams(this.model);
  @override
  List<Object?> get props => [model];
}
