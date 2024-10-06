import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:game_note/firebase/firestore/notification/gn_notification.dart';
import 'package:game_note/routing.dart';
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
    return Slidable(
      endActionPane: ActionPane(
        motion: StretchMotion(),
        children: [
          SlidableAction(
            borderRadius: BorderRadius.circular(8),
            onPressed: (ctx) {
              context
                  .read<NotificationBloc>()
                  .add(NotificationEventDelete(notification.id));
            },
            icon: Icons.delete_outline,
            backgroundColor: Colors.red[500]!,
          )
        ],
      ),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            context
                .read<NotificationBloc>()
                .add(NotificationEventMarkAsRead(notification.id));
          }
          if (notification.notificationType ==
                  GNNotificationType.esportsLeague &&
              notification.relatedId != null) {
            // go to league detail page
            Navigator.of(context).pushNamed(
              Routing.tournamentDetail,
              arguments: notification.relatedId,
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: notification.isRead ? Colors.green[50] : Colors.green[200],
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
                    notification.isRead ? FontWeight.normal : FontWeight.bold,
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
      ),
    );
  }
}
