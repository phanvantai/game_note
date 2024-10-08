import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/common/view_status.dart';

import '../../../domain/repositories/notification_repository.dart';
import '../../../firebase/firestore/notification/gn_notification.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _notificationRepository;

  NotificationBloc(this._notificationRepository)
      : super(const NotificationState()) {
    on<NotificationEventFetch>(_onFetch);
    on<NotificationEventMarkAsRead>(_onMarkAsRead);
    on<NotificationEventMarkAllAsRead>(_onMarkAllAsRead);
    on<NotificationEventDelete>(_onDelete);

    _notificationSubscription =
        _notificationRepository.listenToNotifications().listen((notifications) {
      add(NotificationEventFetch());
    });
  }

  StreamSubscription<List<GNNotification>>? _notificationSubscription;

  _onFetch(
      NotificationEventFetch event, Emitter<NotificationState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    final notifications = await _notificationRepository.getNotifications();
    emit(state.copyWith(
        viewStatus: ViewStatus.success, notifications: notifications));
  }

  _onMarkAsRead(NotificationEventMarkAsRead event,
      Emitter<NotificationState> emit) async {
    await _notificationRepository.setNotificationAsRead(event.notificationId);
    final notifications = state.notifications.map((notification) {
      if (notification.id == event.notificationId) {
        return notification.copyWith(isRead: true);
      }
      return notification;
    }).toList();
    emit(state.copyWith(notifications: notifications));
  }

  _onMarkAllAsRead(NotificationEventMarkAllAsRead event,
      Emitter<NotificationState> emit) async {
    await _notificationRepository.markAllNotificationsAsRead();
    final notifications = state.notifications.map((notification) {
      return notification.copyWith(isRead: true);
    }).toList();
    emit(state.copyWith(notifications: notifications));
  }

  _onDelete(
      NotificationEventDelete event, Emitter<NotificationState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    await _notificationRepository.deleteNotification(event.notificationId);
    final notifications = state.notifications
        .where((notification) => notification.id != event.notificationId)
        .toList();
    emit(state.copyWith(
        notifications: notifications, viewStatus: ViewStatus.success));
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }
}
