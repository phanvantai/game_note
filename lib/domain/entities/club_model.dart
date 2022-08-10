import 'package:equatable/equatable.dart';

class ClubModel extends Equatable {
  final String name;

  const ClubModel({required this.name});
  @override
  List<Object?> get props => [name];
}
