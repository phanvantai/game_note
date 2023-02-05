import 'package:equatable/equatable.dart';

class TeamModel extends Equatable {
  final String uid;
  final String name;
  final int level;
  final String leagueUid;

  const TeamModel({
    required this.uid,
    required this.name,
    required this.level,
    required this.leagueUid,
  });
  @override
  List<Object?> get props => [name, level];
}
