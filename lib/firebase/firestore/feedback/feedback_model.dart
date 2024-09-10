import 'package:cloud_firestore/cloud_firestore.dart';

import '../../gn_collection.dart';

class FeedbackModel {
  final String id;
  final int status;
  final String title;
  final String detail;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeedbackModel({
    required this.id,
    required this.status,
    required this.title,
    required this.detail,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeedbackModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return FeedbackModel(
      id: snapshot.id,
      status: data[GNFeedbackFields.status],
      title: data[GNFeedbackFields.title],
      detail: data[GNFeedbackFields.detail],
      userId: data[GNFeedbackFields.userId],
      createdAt: data[GNCommonFields.createdAt].toDate(),
      updatedAt: data[GNCommonFields.updatedAt].toDate(),
    );
  }
}
