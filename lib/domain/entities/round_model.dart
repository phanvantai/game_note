import 'package:equatable/equatable.dart';

class RoundModel extends Equatable {
  final int id;
  final int tournamentId;

  const RoundModel({required this.id, required this.tournamentId});
  @override
  List<Object?> get props => [id, tournamentId];
}
