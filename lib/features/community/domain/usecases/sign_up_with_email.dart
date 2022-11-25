import 'package:equatable/equatable.dart';

import '../../../../core/common/failure.dart';
import '../../../../core/common/result.dart';
import '../../../../core/common/usecase.dart';
import '../entities/user_model.dart';
import '../repositories/auth_repository.dart';

class SignUpWithEmail implements Usecase<UserModel, SignUpWithEmailParams> {
  final AuthRepository repository;

  SignUpWithEmail(this.repository);
  @override
  Future<Result<Failure, UserModel>> call(SignUpWithEmailParams params) {
    return repository.signUpWithEmail(params.email, params.password);
  }
}

class SignUpWithEmailParams extends Equatable {
  final String email;
  final String password;

  const SignUpWithEmailParams(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}
