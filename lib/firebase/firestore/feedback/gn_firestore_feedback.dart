import 'package:cloud_firestore/cloud_firestore.dart';

import '../../gn_collection.dart';
import '../gn_firestore.dart';
import 'feedback_model.dart';

extension GNFirestoreFeedback on GNFirestore {
  Future<void> createFeedback(
      String title, String detail, String userId) async {
    await firestore.collection(GNCollection.feedbacks).add({
      GNFeedbackFields.status: 0,
      GNFeedbackFields.title: title,
      GNFeedbackFields.detail: detail,
      GNFeedbackFields.userId: userId,
      GNCommonFields.createdAt: FieldValue.serverTimestamp(),
      GNCommonFields.updatedAt: FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFeedbackStatus(String feedbackId, int status) async {
    await firestore
        .collection(GNCollection.feedbacks)
        .doc(feedbackId)
        .update({GNFeedbackFields.status: status});
  }

  Future<List<FeedbackModel>> getAllFeedback() async {
    QuerySnapshot querySnapshot =
        await firestore.collection(GNCollection.feedbacks).get();

    List<FeedbackModel> feedbackList = [];
    for (var doc in querySnapshot.docs) {
      feedbackList.add(FeedbackModel.fromSnapshot(doc));
    }

    return feedbackList;
  }
}
