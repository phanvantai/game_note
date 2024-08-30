import 'package:cloud_firestore/cloud_firestore.dart';

import '../gn_collection.dart';

class GNFirestore {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseFirestore get firestore => _firestore;

  Future<void> createFeedback(
      String title, String detail, String userId) async {
    await _firestore.collection(GNCollection.feedbacks).add({
      GNFeedbackFields.status: 0,
      GNFeedbackFields.title: title,
      GNFeedbackFields.detail: detail,
      GNFeedbackFields.userId: userId,
      GNFeedbackFields.createdAt: FieldValue.serverTimestamp(),
      GNFeedbackFields.updatedAt: FieldValue.serverTimestamp(),
    });
  }
}

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
      createdAt: data[GNFeedbackFields.createdAt].toDate(),
      updatedAt: data[GNFeedbackFields.updatedAt].toDate(),
    );
  }
}
