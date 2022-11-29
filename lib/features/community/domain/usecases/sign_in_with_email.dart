import 'package:equatable/equatable.dart';
import 'package:game_note/core/common/result.dart';
import 'package:game_note/core/common/failure.dart';
import 'package:game_note/core/common/usecase.dart';
import 'package:game_note/features/community/domain/entities/user_model.dart';
import 'package:game_note/features/community/domain/repositories/auth_repository.dart';

class SignInWithEmail implements Usecase<UserModel, SignInWithEmailParams> {
  final AuthRepository repository;

  SignInWithEmail(this.repository);
  @override
  Future<Result<Failure, UserModel>> call(SignInWithEmailParams params) {
    return repository.signInWithEmail(params.email, params.password);
  }
}

class SignInWithEmailParams extends Equatable {
  final String email;
  final String password;

  const SignInWithEmailParams(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}
