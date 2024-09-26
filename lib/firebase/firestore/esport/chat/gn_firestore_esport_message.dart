import 'package:game_note/firebase/firestore/gn_firestore.dart';

import 'gn_esport_message.dart';

extension GNFirestoreEsportMessage on GNFirestore {
  // get the latest 50 messages
  Future<List<GNEsportMessage>> fetchLatestMessages() async {
    final querySnapshot = await firestore
        .collection(GNEsportMessage.collectionName)
        .orderBy(GNEsportMessage.fieldTimestamp, descending: true)
        .limit(50)
        .get();

    return querySnapshot.docs
        .map((doc) => GNEsportMessage.fromFirestore(doc))
        .toList();
  }

  // add a new message
  Future<void> sendMessage(String userId, String content) async {
    final message = GNEsportMessage(
      id: '', // Firestore will assign the ID
      userId: userId,
      content: content,
      timestamp: DateTime.now(),
      status: null, // message do not have status yet
    );

    await firestore
        .collection(GNEsportMessage.collectionName)
        .add(message.toMap());
  }

  Stream<List<GNEsportMessage>> listenForNewMessages() {
    return firestore
        .collection(GNEsportMessage.collectionName)
        .orderBy(GNEsportMessage.fieldTimestamp, descending: true)
        .limit(50) // Listen for the latest 50 messages
        .snapshots() // This will return a stream of snapshots in real-time
        .map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => GNEsportMessage.fromFirestore(doc))
          .toList();
    });
  }

  // delete a message
  Future<void> deleteMessage(String messageId) async {
    await firestore
        .collection(GNEsportMessage.collectionName)
        .doc(messageId)
        .delete();
  }
}
