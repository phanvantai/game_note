import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:game_note/firebase/auth/gn_auth.dart';
import 'package:game_note/firebase/firestore/gn_firestore.dart';
import 'package:game_note/firebase/firestore/user/gn_user.dart';
import 'package:game_note/firebase/gn_collection.dart';
import 'package:game_note/firebase/storage/gn_storage.dart';
import 'package:game_note/injection_container.dart';
import 'package:image_picker/image_picker.dart';

import '../esport/group/gn_esport_group.dart';
import 'user_role.dart';

extension GNFirestoreUser on GNFirestore {
  Future<void> createUserIfNeeded(User user) async {
    final userRef = firestore.collection(GNUser.collectionName).doc(user.uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      await userRef.set({
        GNUser.displayNameKey: user.displayName,
        GNUser.phoneNumberKey: user.phoneNumber,
        GNUser.emailKey: user.email,
        GNUser.photoUrlKey: user.photoURL,
        GNUser.roleKey: UserRole.user.name,
        GNCommonFields.createdAt: FieldValue.serverTimestamp(),
        GNCommonFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<GNUser> getCurrentUser() async {
    final user = getIt<GNAuth>().currentUser;
    if (user == null) {
      throw Exception('User is not signed in');
    }
    final userDoc =
        await firestore.collection(GNUser.collectionName).doc(user.uid).get();
    return GNUser.fromFireStore(userDoc);
  }

  Future<GNUser?> getUserById(String userId) async {
    final userDoc =
        await firestore.collection(GNUser.collectionName).doc(userId).get();
    if (!userDoc.exists) {
      return null;
    }
    return GNUser.fromFireStore(userDoc);
  }

  Future<void> deleteCurrentUser() async {
    final user = getIt<GNAuth>().currentUser;
    if (user == null) {
      throw Exception('User is not signed in');
    }
    await firestore.collection(GNUser.collectionName).doc(user.uid).delete();
    await user.delete();
  }

  Future<void> deleteAvatar() async {
    final user = getIt<GNAuth>().currentUser;
    if (user == null) {
      throw Exception('User is not signed in');
    }
    final currentUserModel = await getCurrentUser();
    final oldPhotoUrl = currentUserModel.photoUrl;

    if (oldPhotoUrl == null || oldPhotoUrl.isEmpty) {
      return;
    }

    // delete avatar file from storage
    final storage = getIt<GNStorage>();
    await storage.deleteAvatarByUrl(oldPhotoUrl);

    // update firebase user photoUrl to null
    await FirebaseAuth.instance.currentUser?.updatePhotoURL(null);

    await firestore.collection(GNUser.collectionName).doc(user.uid).update({
      GNUser.photoUrlKey: null,
      GNCommonFields.updatedAt: FieldValue.serverTimestamp(),
    });
  }

  Future<void> changeAvatar(XFile imageFile) async {
    final user = getIt<GNAuth>().currentUser;
    final storage = getIt<GNStorage>();
    if (user == null) {
      throw Exception('User is not signed in');
    }
    final photoUrl = await storage.uploadAvatarFile(imageFile);
    // update firebase user photoUrl
    FirebaseAuth.instance.currentUser?.updatePhotoURL(photoUrl);

    await firestore.collection(GNUser.collectionName).doc(user.uid).update({
      GNUser.photoUrlKey: photoUrl,
      GNCommonFields.updatedAt: FieldValue.serverTimestamp(),
    });
  }

  // search user by displayName or email or phoneNumber
  Future<List<GNUser>> searchUser(String query) async {
    final user = getIt<GNAuth>().currentUser;
    if (user == null) {
      throw Exception('User is not signed in');
    }
    // Perform three separate queries
    final displayNameQuery = firestore
        .collection(GNUser.collectionName)
        .where(GNUser.displayNameKey, isGreaterThanOrEqualTo: query)
        .where(GNUser.displayNameKey, isLessThan: '$query\uf8ff')
        .get();

    final emailQuery = firestore
        .collection(GNUser.collectionName)
        .where(GNUser.emailKey, isGreaterThanOrEqualTo: query)
        .where(GNUser.emailKey, isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    final phoneNumberQuery = firestore
        .collection(GNUser.collectionName)
        .where(GNUser.phoneNumberKey, isGreaterThanOrEqualTo: query)
        .where(GNUser.phoneNumberKey, isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    // Wait for all the queries to finish
    final results =
        await Future.wait([displayNameQuery, emailQuery, phoneNumberQuery]);

    // Create a map to hold unique documents by their document ID
    final Map<String, QueryDocumentSnapshot> uniqueDocs = {};

    // Add documents from each query, using the document ID as the key
    for (final result in results) {
      for (final doc in result.docs) {
        uniqueDocs[doc.id] =
            doc; // This ensures that duplicates are overwritten
      }
    }
    return uniqueDocs.values.map((doc) => GNUser.fromFireStore(doc)).toList();
  }

  Future<List<GNUser>> searchUserByGroup(String groupId, String query) async {
    final user = getIt<GNAuth>().currentUser;
    if (user == null) {
      throw Exception('User is not signed in');
    }
    final groupDoc = await firestore
        .collection(GNEsportGroup.collectionName)
        .doc(groupId)
        .get();
    if (!groupDoc.exists) {
      throw Exception('Group not found');
    }
    final group = GNEsportGroup.fromFirestore(groupDoc);
    if (!group.members.contains(user.uid)) {
      throw Exception('User is not a member of the group');
    }

    // Perform three separate queries
    final displayNameQuery = firestore
        .collection(GNUser.collectionName)
        .where(GNUser.displayNameKey, isGreaterThanOrEqualTo: query)
        .where(GNUser.displayNameKey, isLessThan: '$query\uf8ff')
        .get();

    final emailQuery = firestore
        .collection(GNUser.collectionName)
        .where(GNUser.emailKey, isGreaterThanOrEqualTo: query)
        .where(GNUser.emailKey, isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    final phoneNumberQuery = firestore
        .collection(GNUser.collectionName)
        .where(GNUser.phoneNumberKey, isGreaterThanOrEqualTo: query)
        .where(GNUser.phoneNumberKey, isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    // Wait for all the queries to finish
    final results =
        await Future.wait([displayNameQuery, emailQuery, phoneNumberQuery]);

    // Create a map to hold unique documents by their document ID
    final Map<String, QueryDocumentSnapshot> uniqueDocs = {};

    // Add documents from each query, using the document ID as the key
    for (final result in results) {
      for (final doc in result.docs) {
        uniqueDocs[doc.id] =
            doc; // This ensures that duplicates are overwritten
      }
    }
    return uniqueDocs.values
        .map((doc) => GNUser.fromFireStore(doc))
        .where((user) => group.members.contains(user.id))
        .toList();
  }

  // update fcm token
  Future<void> updateFcmToken(String fcmToken) async {
    final user = getIt<GNAuth>().currentUser;
    if (user == null) {
      throw Exception('User is not signed in');
    }
    await firestore.collection(GNUser.collectionName).doc(user.uid).update({
      GNUser.fcmTokenKey: fcmToken,
      GNCommonFields.updatedAt: FieldValue.serverTimestamp(),
    });
  }
}
