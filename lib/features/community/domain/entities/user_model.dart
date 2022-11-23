import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;

  const UserModel({
    required this.id,
    required this.email,
  });
  @override
  List<Object?> get props => [id, email];
}
