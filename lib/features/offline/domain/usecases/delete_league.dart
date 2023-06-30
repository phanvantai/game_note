import 'package:dartz/dartz.dart';

import '../../../../core/common/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/league_repository.dart';

class DeleteLeague extends UseCase<int, GetLeagueParams> {
  final LeagueRepository repository;

  DeleteLeague(this.repository);
  @override
  Future<Either<Failure, int>> call(GetLeagueParams params) {
    return repository.deleteLeauge(params);
  }
}
