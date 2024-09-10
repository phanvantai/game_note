import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:game_note/firebase/firestore/gn_firestore.dart';
import 'package:game_note/firebase/gn_collection.dart';

extension GNFirestoreInvitation on GNFirestore {
  Future<void> inviteUserToTeam(
      String message, String teamId, String userId) async {
    CollectionReference invitationsRef = firestore
        .collection(GNCollection.teams)
        .doc(teamId)
        .collection(GNCollection.invitations);

    await invitationsRef.add({
      GNInvitationFields.userId: userId,
      GNInvitationFields.status: 'pending',
      GNInvitationFields.sentAt: Timestamp.fromDate(DateTime.now()),
      GNInvitationFields.message: message,
    });
  }
}
