import 'package:equatable/equatable.dart';

class ClubModel extends Equatable {
  final int? id;
  final String name;
  final String icon;

  const ClubModel({this.id, required this.name, required this.icon});
  @override
  List<Object?> get props => [id, name, icon];
}
