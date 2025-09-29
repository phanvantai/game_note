import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

enum GNNotificationType {
  unknown,
  esportsGroup,
  esportsLeague,
}

extension GNNotificationTypeExtension on GNNotificationType {
  String get value {
    switch (this) {
      case GNNotificationType.esportsGroup:
        return 'esport_group';
      case GNNotificationType.esportsLeague:
        return 'esport_league';
      case GNNotificationType.unknown:
        return 'unknown';
    }
  }

  static GNNotificationType fromString(String value) {
    switch (value) {
      case 'esport_group':
        return GNNotificationType.esportsGroup;
      case 'esport_league':
        return GNNotificationType.esportsLeague;
      default:
        return GNNotificationType.unknown;
    }
  }

  Widget get icon {
    switch (this) {
      case GNNotificationType.esportsGroup:
        return SvgPicture.asset('assets/svg/users-line-solid.svg');
      case GNNotificationType.esportsLeague:
        return SvgPicture.asset('assets/svg/trophy-solid.svg');
      case GNNotificationType.unknown:
        return const Icon(Icons.notifications);
    }
  }
}

class GNNotification extends Equatable {
  final String id; // Notification ID
  final String userId; // ID of the user who receives the notification
  final String title; // Notification title
  final String message; // Notification message
  final String
      type; // Type of notification (e.g., "group_invite", "league_invite")
  final DateTime timestamp; // Time when the notification was created
  final bool isRead; // Whether the notification has been read
  final String?
      relatedId; // ID related to the notification (groupId or leagueId)

  final GNUser? user; // User who receives the notification

  static const String collectionName = 'notifications';

  static const String fieldId = 'id';
  static const String fieldUserId = 'userId';
  static const String fieldTitle = 'title';
  static const String fieldMessage = 'message';
  static const String fieldType = 'type';
  static const String fieldTimestamp = 'timestamp';
  static const String fieldIsRead = 'isRead';
  static const String fieldRelatedId = 'relatedId';

  const GNNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.relatedId,
    this.user,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        message,
        type,
        timestamp,
        isRead,
        relatedId,
        user,
      ];

  GNNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    String? relatedId,
    GNUser? user,
  }) {
    return GNNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      user: user ?? this.user,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      fieldUserId: userId,
      fieldTitle: title,
      fieldMessage: message,
      fieldType: type,
      fieldTimestamp: Timestamp.fromDate(timestamp),
      fieldIsRead: isRead,
      if (relatedId != null) fieldRelatedId: relatedId,
    };
  }

  factory GNNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GNNotification(
      id: doc.id,
      userId: data[fieldUserId],
      title: data[fieldTitle],
      message: data[fieldMessage],
      type: data[fieldType],
      timestamp: (data[fieldTimestamp] as Timestamp).toDate(),
      isRead: data[fieldIsRead],
      relatedId: data[fieldRelatedId],
    );
  }

  GNNotificationType get notificationType {
    return GNNotificationTypeExtension.fromString(type);
  }
}
