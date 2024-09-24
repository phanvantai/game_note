import '../../firebase/firestore/notification/gn_notification.dart';

abstract class NotificationRepository {
  Future<List<GNNotification>> getNotifications();

  Future<void> setNotificationAsRead(String notificationId);
}
