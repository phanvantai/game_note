import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/firebase/firestore/notification/gn_notification.dart';
import 'package:pes_arena/routing.dart';
import 'package:intl/intl.dart';

import 'bloc/notification_bloc.dart';

class NotificationItem extends StatelessWidget {
  final GNNotification notification;
  const NotificationItem({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isUnread = !notification.isRead;
    final accent = isUnread ? colorScheme.secondary : colorScheme.outline;

    return Slidable(
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            borderRadius: BorderRadius.circular(16),
            onPressed: (ctx) {
              context.read<NotificationBloc>().add(
                NotificationEventDelete(notification.id),
              );
            },
            icon: Icons.delete_outline,
            backgroundColor: colorScheme.error,
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (!notification.isRead) {
            context.read<NotificationBloc>().add(
              NotificationEventMarkAsRead(notification.id),
            );
          }
          if (notification.notificationType ==
                  GNNotificationType.esportsLeague &&
              notification.relatedId != null) {
            context.push(Routing.tournamentDetailPath(notification.relatedId!));
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.surface,
            border: Border.all(
              color: isUnread
                  ? colorScheme.secondary.withValues(alpha: 0.28)
                  : colorScheme.outline.withValues(alpha: 0.42),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: isUnread ? 0.13 : 0.04),
                colorScheme.surface,
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: isUnread
                          ? colorScheme.secondary.withValues(alpha: 0.13)
                          : colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.72,
                            ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: notification.notificationType.icon,
                  ),
                  if (isUnread)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colorScheme.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: isUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TimeBadge(timestamp: notification.timestamp),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification.relatedId != null) ...[
                      const SizedBox(height: 10),
                      _NotificationChip(
                        label: notification.notificationType.label,
                        unread: isUnread,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  final DateTime timestamp;

  const _TimeBadge({required this.timestamp});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        DateFormat('dd/MM\nHH:mm').format(timestamp.toLocal()),
        textAlign: TextAlign.right,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.05,
        ),
      ),
    );
  }
}

class _NotificationChip extends StatelessWidget {
  final String label;
  final bool unread;

  const _NotificationChip({required this.label, required this.unread});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = unread ? colorScheme.secondary : colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

extension on GNNotificationType {
  String get label {
    switch (this) {
      case GNNotificationType.esportsGroup:
        return 'Nhóm';
      case GNNotificationType.esportsLeague:
        return 'Giải đấu';
      case GNNotificationType.unknown:
        return 'Thông báo';
    }
  }
}
