import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:game_note/firebase/auth/gn_auth.dart';
import 'package:game_note/firebase/firestore/gn_firestore.dart';
import 'package:game_note/firebase/firestore/user/user_model.dart';
import 'package:game_note/firebase/gn_collection.dart';
import 'package:game_note/injection_container.dart';

import 'user_role.dart';

extension GNFirestoreUser on GNFirestore {
  Future<void> createUserIfNeeded(User user) async {
    final userRef = firestore.collection(GNCollection.users).doc(user.uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      await userRef.set({
        GNUserFields.displayName: user.displayName,
        GNUserFields.phoneNumber: user.phoneNumber,
        GNUserFields.email: user.email,
        GNUserFields.photoUrl: user.photoURL,
        GNUserFields.role: UserRole.user.name,
        GNCommonFields.createdAt: FieldValue.serverTimestamp(),
        GNCommonFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<UserModel> getCurrentUser() async {
    final user = getIt<GNAuth>().currentUser;
    if (user == null) {
      throw Exception('User is not signed in');
    }
    final userDoc =
        await firestore.collection(GNCollection.users).doc(user.uid).get();
    return UserModel.fromSnapshot(userDoc);
  }

  Future<UserModel> getUserById(String userId) async {
    final userDoc =
        await firestore.collection(GNCollection.users).doc(userId).get();
    return UserModel.fromSnapshot(userDoc);
  }

  Future<void> deleteCurrentUser() async {
    final user = getIt<GNAuth>().currentUser;
    if (user == null) {
      throw Exception('User is not signed in');
    }
    await firestore.collection(GNCollection.users).doc(user.uid).delete();
    await user.delete();
  }
}
