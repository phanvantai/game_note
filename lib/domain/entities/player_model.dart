import 'package:equatable/equatable.dart';

class PlayerModel extends Equatable {
  final String fullname;
  final String level;
  final int? id;

  const PlayerModel({required this.fullname, this.level = "Noob", this.id});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullname': fullname,
      'level': level,
    };
  }

  @override
  String toString() {
    return 'Player{id: $id, fullname: $fullname, level: $level}';
  }

  @override
  List<Object?> get props => [fullname, level, id];
}
