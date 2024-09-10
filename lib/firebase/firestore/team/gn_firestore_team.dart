import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:game_note/firebase/firestore/gn_firestore.dart';
import 'package:game_note/firebase/firestore/team/gn_team.dart';

import '../../gn_collection.dart';

extension GNFirestoreTeam on GNFirestore {
  Future<List<GNTeam>> getTeams() async {
    CollectionReference teamsRef = firestore.collection(GNCollection.teams);
    QuerySnapshot querySnapshot = await teamsRef.get();

    return querySnapshot.docs.map((doc) => GNTeam.fromSnapshot(doc)).toList();
  }

  Future<List<GNTeam>> getTeamsByUser(String userId) async {
    CollectionReference teamsRef = firestore.collection(GNCollection.teams);
    QuerySnapshot querySnapshot =
        await teamsRef.where(GNTeamFields.members, arrayContains: userId).get();

    return querySnapshot.docs.map((doc) => GNTeam.fromSnapshot(doc)).toList();
  }

  Future<void> createTeam(String teamName) async {
    CollectionReference teamsRef = firestore.collection(GNCollection.teams);
    DocumentReference docRef = teamsRef.doc();

    GNTeam team = GNTeam(
      teamId: docRef.id,
      name: teamName,
      ownerId: currentUser.uid,
      members: [currentUser.uid],
      managers: [currentUser.uid],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await docRef.set(team.toMap());
  }

  Future<void> inviteUserToTeam(
      String message, String teamId, String userId) async {
    CollectionReference teamsRef = firestore.collection(GNCollection.teams);
    DocumentReference docRef = teamsRef.doc(teamId);

    final teamSnapshot = await docRef.get();
    if (!teamSnapshot.exists) {
      throw Exception('Team does not exist');
    }

    final team = GNTeam.fromSnapshot(teamSnapshot);
    if (!team.managers.contains(FirebaseAuth.instance.currentUser!.uid)) {
      throw Exception('User is not a manager of the team');
    }

    final members = team.members;
    members.add(userId);

    await docRef.update({
      GNTeamFields.members: members,
    });
  }
}
