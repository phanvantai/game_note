import 'package:game_note/core/common/failure.dart';
import 'package:game_note/core/common/result.dart';
import 'package:game_note/features/community/domain/entities/user_model.dart';

abstract class AuthRepository {
  Future<Result<Failure, UserModel>> signInWithEmail(
      String email, String password);
}
