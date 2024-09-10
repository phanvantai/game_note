import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../gn_collection.dart';

class GNTeam extends Equatable {
  final String teamId;
  final String name;
  final String ownerId;
  final List<String> members;
  final List<String> managers;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GNTeam({
    required this.teamId,
    required this.name,
    required this.ownerId,
    required this.members,
    required this.managers,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert a GNTeam instance into a Map instance
  Map<String, dynamic> toMap() {
    return {
      GNTeamFields.teamId: teamId,
      GNTeamFields.name: name,
      GNTeamFields.ownerId: ownerId,
      GNTeamFields.members: members,
      GNTeamFields.managers: managers,
      GNCommonFields.createdAt: Timestamp.fromDate(createdAt),
      GNCommonFields.updatedAt: Timestamp.fromDate(updatedAt),
    };
  }

  // From Firestore data to GNTeam instance
  factory GNTeam.fromSnapshot(DocumentSnapshot snapshot) {
    var data = snapshot.data() as Map<String, dynamic>;
    return GNTeam(
      teamId: data[GNTeamFields.teamId],
      name: data[GNTeamFields.name],
      ownerId: data[GNTeamFields.ownerId],
      members: List<String>.from(data[GNTeamFields.members]),
      managers: List<String>.from(data[GNTeamFields.managers]),
      createdAt: (data[GNCommonFields.createdAt] as Timestamp).toDate(),
      updatedAt: (data[GNCommonFields.updatedAt] as Timestamp).toDate(),
    );
  }

  @override
  List<Object?> get props =>
      [teamId, name, ownerId, members, managers, createdAt, updatedAt];
}
