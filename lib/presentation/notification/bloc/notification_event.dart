part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationEventFetch extends NotificationEvent {}

class NotificationEventMarkAsRead extends NotificationEvent {
  final String notificationId;

  const NotificationEventMarkAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class NotificationEventMarkAllAsRead extends NotificationEvent {}

class NotificationEventDelete extends NotificationEvent {
  final String notificationId;

  const NotificationEventDelete(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}
