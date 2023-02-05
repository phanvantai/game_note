import 'package:equatable/equatable.dart';

class LeagueModel extends Equatable {
  final String uid;
  final String name;
  final String nation;

  const LeagueModel({
    required this.uid,
    required this.name,
    required this.nation,
  });
  @override
  List<Object?> get props => [];
}
