part of 'notification_bloc.dart';

class NotificationState extends Equatable {
  final ViewStatus viewStatus;
  final List<GNNotification> notifications;

  const NotificationState({
    this.viewStatus = ViewStatus.initial,
    this.notifications = const [],
  });

  NotificationState copyWith({
    ViewStatus? viewStatus,
    List<GNNotification>? notifications,
  }) {
    return NotificationState(
      viewStatus: viewStatus ?? this.viewStatus,
      notifications: notifications ?? this.notifications,
    );
  }

  @override
  List<Object?> get props => [notifications];

  int get unreadNotificationsCount =>
      notifications.where((notification) => !notification.isRead).length;
}
