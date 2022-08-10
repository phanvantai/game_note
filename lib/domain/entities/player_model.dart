import 'package:equatable/equatable.dart';

class PlayerModel extends Equatable {
  final String name;

  const PlayerModel({required this.name});

  @override
  List<Object?> get props => [name];
}
