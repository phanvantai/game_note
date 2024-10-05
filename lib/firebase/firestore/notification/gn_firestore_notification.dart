import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:game_note/firebase/firestore/user/gn_firestore_user.dart';

import '../gn_firestore.dart';
import '../user/gn_user.dart';
import 'gn_notification.dart';

extension GNFirestoreNotification on GNFirestore {
  // Function to get all notifications for a user
  Future<List<GNNotification>> getUserNotifications(String userId) async {
    // Query notifications where userId matches
    QuerySnapshot querySnapshot = await firestore
        .collection(GNUser.collectionName)
        .doc(userId)
        .collection(GNNotification.collectionName)
        // Sort by time
        .orderBy(GNNotification.fieldTimestamp, descending: true)
        .get();

    // get user data
    GNUser? user = await getUserById(userId);

    // Map the query results to a list of GNNotification objects
    return querySnapshot.docs
        .map((doc) => GNNotification.fromFirestore(doc).copyWith(user: user))
        .toList();
  }

  // Function to set a notification as read
  Future<void> setNotificationAsRead(
      String userId, String notificationId) async {
    // Get the notification document
    DocumentReference notificationDoc = firestore
        .collection(GNUser.collectionName)
        .doc(userId)
        .collection(GNNotification.collectionName)
        .doc(notificationId);

    // Update the notification document
    await notificationDoc.update({GNNotification.fieldIsRead: true});
  }

  // listen to notifications of a user with userId
  Stream<List<GNNotification>> listenToUserNotifications(String userId) {
    // Query notifications where userId matches
    return firestore
        .collection(GNUser.collectionName)
        .doc(userId)
        .collection(GNNotification.collectionName)
        // Sort by time
        .orderBy(GNNotification.fieldTimestamp, descending: true)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs
            .map((doc) => GNNotification.fromFirestore(doc))
            .toList());
  }
}
