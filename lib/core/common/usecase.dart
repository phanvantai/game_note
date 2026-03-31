import 'failure.dart';
import 'result.dart';

abstract class Usecase<T, Params> {
  Future<Result<Failure, T>> call(Params params);
}
