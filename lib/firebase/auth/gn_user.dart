import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:game_note/firebase/gn_collection.dart';

class GnUser {
  Future<void> updateUserInformation(User user,
      {String? displayName, String? photoUrl}) async {
    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }

    // Optional: Store additional user data in Firestore
    final firestore = FirebaseFirestore.instance;
    firestore.collection(GnCollection.users).doc(user.uid).set({
      'displayName': displayName ?? user.displayName,
      'phoneNumber': user.phoneNumber,
      'email': user.email,
      'photoUrl': photoUrl ?? user.photoURL,
    });
  }
}
