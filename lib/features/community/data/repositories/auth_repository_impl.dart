import 'package:game_note/core/common/exception.dart';
import 'package:game_note/features/community/data/datasources/auth_datasource.dart';
import 'package:game_note/features/community/domain/entities/user_model.dart';
import 'package:game_note/core/common/result.dart';
import 'package:game_note/core/common/failure.dart';
import 'package:game_note/features/community/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDatasource datasource;

  AuthRepositoryImpl(this.datasource);
  @override
  Future<Result<Failure, UserModel>> signInWithEmail(
      String email, String password) async {
    try {
      // login
      return Success(await datasource.signInWithEmail(email, password));
    } on ServerException catch (e) {
      return Error(RemoteFailure(e.message));
    }
  }
}
