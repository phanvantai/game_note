import 'package:equatable/equatable.dart';

class LeagueModel extends Equatable {
  final int id;
  final String name;
  final DateTime dateTime = DateTime.now();

  LeagueModel({required this.id, required this.name});
  @override
  List<Object?> get props => [id, name, dateTime];
}
