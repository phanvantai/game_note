import 'failure.dart';
import 'result.dart';

abstract class Usecase<Type, Params> {
  Future<Result<Failure, Type>> call(Params params);
}
