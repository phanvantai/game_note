import 'package:cloud_firestore/cloud_firestore.dart';

import '../../gn_collection.dart';

class GNInvitation {
  String invitationId;
  String userId;
  String status; // pending, accepted, rejected
  DateTime sentAt;
  DateTime? respondedAt;
  String message;

  GNInvitation({
    required this.invitationId,
    required this.userId,
    required this.status,
    required this.sentAt,
    this.respondedAt,
    required this.message,
  });

  Map<String, dynamic> toMap() {
    return {
      GNInvitationFields.invitationId: invitationId,
      GNInvitationFields.userId: userId,
      GNInvitationFields.status: status,
      GNInvitationFields.sentAt: sentAt,
      GNInvitationFields.respondedAt:
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      GNInvitationFields.message: message,
    };
  }

  factory GNInvitation.fromSnapshot(DocumentSnapshot snapshot) {
    var data = snapshot.data() as Map<String, dynamic>;
    return GNInvitation(
      invitationId: snapshot.id,
      userId: data[GNInvitationFields.userId],
      status: data[GNInvitationFields.status],
      sentAt: data[GNInvitationFields.sentAt].toDate(),
      respondedAt: data[GNInvitationFields.respondedAt] != null
          ? (data[GNInvitationFields.respondedAt] as Timestamp).toDate()
          : null,
      message: snapshot[GNInvitationFields.message],
    );
  }
}
