import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:game_note/core/error/failure.dart';
import 'package:game_note/core/usecase/usecase.dart';
import 'package:game_note/domain/entities/round_model.dart';
import 'package:game_note/domain/repositories/round_repository.dart';

class CreateRound extends UseCase<RoundModel, CreateRoundParams> {
  final RoundRepository repository;

  CreateRound(this.repository);
  @override
  Future<Either<Failure, RoundModel>> call(CreateRoundParams params) {
    return repository.createRound(params.model);
  }
}

class CreateRoundParams extends Equatable {
  final RoundModel model;

  const CreateRoundParams(this.model);
  @override
  List<Object?> get props => [model];
}
