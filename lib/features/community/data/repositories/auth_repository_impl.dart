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
      // sign in
      return Success(await datasource.signInWithEmail(email, password));
    } on ServerException catch (e) {
      return Error(RemoteFailure(e.message));
    }
  }

  @override
  Future<Result<Failure, UserModel>> signUpWithEmail(
      String email, String password) async {
    try {
      // sign up
      return Success(
          await datasource.createUserWithEmailAndPassword(email, password));
    } on ServerException catch (e) {
      return Error(RemoteFailure(e.message));
    }
  }
}
