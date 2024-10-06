import '../../firebase/firestore/notification/gn_notification.dart';

abstract class NotificationRepository {
  Future<List<GNNotification>> getNotifications();

  Future<void> setNotificationAsRead(String notificationId);

  Stream<List<GNNotification>> listenToNotifications();

  Future<void> markAllNotificationsAsRead();

  Future<void> deleteNotification(String notificationId);
}
