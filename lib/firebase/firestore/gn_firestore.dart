import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user/gn_user.dart';

class GNFirestore {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseFirestore get firestore => _firestore;

  User get currentUser {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User is not logged in');
    }
    return currentUser;
  }

  Future<Map<String, GNUser>> getUsersById(List<String> userIds) async {
    if (userIds.isEmpty) return {};
    final uniqueIds = userIds.toSet().toList();
    const batchSize = 10;
    final users = <String, GNUser>{};
    for (var i = 0; i < uniqueIds.length; i += batchSize) {
      final batch = uniqueIds.skip(i).take(batchSize).toList();
      final snap = await _firestore
          .collection(GNUser.collectionName)
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      for (final doc in snap.docs) {
        users[doc.id] = GNUser.fromFireStore(doc);
      }
    }
    return users;
  }
}
