import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pes_arena/firebase/firestore/notification/gn_notification.dart';
import 'package:pes_arena/routing.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Slidable(
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            borderRadius: BorderRadius.circular(12),
            onPressed: (ctx) {
              context
                  .read<NotificationBloc>()
                  .add(NotificationEventDelete(notification.id));
            },
            icon: Icons.delete_outline,
            backgroundColor: colorScheme.error,
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (!notification.isRead) {
            context
                .read<NotificationBloc>()
                .add(NotificationEventMarkAsRead(notification.id));
          }
          if (notification.notificationType ==
                  GNNotificationType.esportsLeague &&
              notification.relatedId != null) {
            Navigator.of(context).pushNamed(
              Routing.tournamentDetail,
              arguments: notification.relatedId,
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: notification.isRead
                ? colorScheme.surface
                : colorScheme.secondaryContainer.withValues(alpha: 0.4),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: SizedBox(
              width: 36,
              height: 36,
              child: notification.notificationType.icon,
            ),
            title: Text(
              notification.title,
              style: textTheme.titleSmall?.copyWith(
                fontWeight:
                    notification.isRead ? FontWeight.normal : FontWeight.w600,
              ),
            ),
            subtitle: Text(
              notification.message,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              DateFormat('dd/MM\nHH:mm')
                  .format(notification.timestamp.toLocal()),
              textAlign: TextAlign.right,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
