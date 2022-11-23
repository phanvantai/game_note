import 'package:game_note/features/community/domain/entities/user_model.dart';
import 'package:game_note/core/common/result.dart';
import 'package:game_note/core/common/failure.dart';
import 'package:game_note/features/community/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<Result<Failure, UserModel>> signInWithEmail(
      String email, String password) async {
    try {
      // login
      return Success(UserModel(id: 'id', email: email));
    } catch (e) {
      return Error(RemoteFailure(e.toString()));
    }
  }
}
