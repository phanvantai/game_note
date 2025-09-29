import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

class GNEsportMessage {
  final String id; // message id
  final String userId; // user who sent the message
  final String content; // message content
  final DateTime timestamp; // when the message was sent
  final String? status; // status of the message: removed, edited, etc.

  final GNUser? user;

  static const String collectionName = 'esports_messages';

  static const String fieldId = 'id';
  static const String fieldUserId = 'userId';
  static const String fieldContent = 'content';
  static const String fieldTimestamp = 'timestamp';
  static const String fieldStatus = 'status';

  const GNEsportMessage({
    required this.id,
    required this.userId,
    required this.content,
    required this.timestamp,
    this.status,
    this.user,
  });

  Map<String, dynamic> toMap() {
    return {
      fieldUserId: userId,
      fieldContent: content,
      fieldTimestamp: timestamp,
      fieldStatus: status,
    };
  }

  factory GNEsportMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GNEsportMessage(
      id: doc.id,
      userId: data[fieldUserId] ?? '',
      content: data[fieldContent] ?? '',
      timestamp: (data[fieldTimestamp] as Timestamp).toDate(),
      status: data[fieldStatus],
    );
  }

  GNEsportMessage copyWith({
    String? id,
    String? userId,
    String? content,
    DateTime? timestamp,
    String? status,
    GNUser? user,
  }) {
    return GNEsportMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      user: user ?? this.user,
    );
  }
}
