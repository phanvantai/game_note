import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/firebase/firestore/notification/gn_notification.dart';
import 'package:intl/intl.dart';

import 'bloc/notification_bloc.dart';

class NotificationItem extends StatelessWidget {
  final GNNotification notification;
  const NotificationItem({
    Key? key,
    required this.notification,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: notification.isRead
          ? null
          : () => context
              .read<NotificationBloc>()
              .add(NotificationEventMarkAsRead(notification.id)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: notification.isRead ? Colors.green[50] : Colors.green[100],
        ),
        child: ListTile(
          leading: SizedBox(
            width: 36,
            height: 36,
            child: notification.notificationType.icon,
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.bold : FontWeight.w900,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            notification.message,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          trailing: Text(
            DateFormat('dd/MM/yyyy\nHH:mm')
                .format(notification.timestamp.toLocal()),
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
