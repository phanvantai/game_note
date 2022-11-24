import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String? email;
  final String? displayName;

  const UserModel({
    required this.uid,
    this.email,
    this.displayName,
  });
  @override
  List<Object?> get props => [uid, email, displayName];
}
