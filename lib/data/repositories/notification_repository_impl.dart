import 'package:firebase_auth/firebase_auth.dart';
import 'package:game_note/domain/repositories/notification_repository.dart';
import 'package:game_note/firebase/firestore/notification/gn_firestore_notification.dart';
import 'package:game_note/firebase/firestore/notification/gn_notification.dart';

import '../../firebase/firestore/gn_firestore.dart';
import '../../injection_container.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  @override
  Future<List<GNNotification>> getNotifications() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return [];
    }
    return getIt<GNFirestore>().getUserNotifications(userId);
  }

  @override
  Future<void> setNotificationAsRead(String notificationId) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    return getIt<GNFirestore>().setNotificationAsRead(userId, notificationId);
  }

  @override
  Stream<List<GNNotification>> listenToNotifications() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    return getIt<GNFirestore>().listenToUserNotifications(userId);
  }
}
