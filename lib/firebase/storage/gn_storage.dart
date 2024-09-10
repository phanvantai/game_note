import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:game_note/firebase/gn_collection.dart';
import 'package:image_picker/image_picker.dart';

class GNStorage {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  FirebaseStorage get storage => _storage;

  Future<String> uploadAvatarFile(XFile file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user signed in');
    }
    // Create a reference to the file in Firebase Storage
    Reference storageRef = _storage.ref().child(
        '${GNCollection.avatars}/${user.uid}/${DateTime.now().millisecondsSinceEpoch}-${file.name}');

    // Upload the file to Firebase Storage
    TaskSnapshot snapshot = await storageRef.putFile(File(file.path));

    // Get the download URL of the uploaded file
    String downloadURL = await snapshot.ref.getDownloadURL();

    // Return the download URL
    return downloadURL;
  }

  Future<void> deleteAvatarByUrl(String downloadUrl) async {
    try {
      // Parse the URL
      final Uri uri = Uri.parse(downloadUrl);

      // Extract the path after '/o/' and before '?'
      final String encodedFilePath = uri.pathSegments.skip(1).join('/');
      final String firstPart = encodedFilePath.split('?').first;
      final String lastPart = firstPart.split('o/').last;
      // Create a reference to the file using the decoded file path
      Reference storageRef = FirebaseStorage.instance.ref().child(lastPart);

      // Delete the file
      await storageRef.delete();
      if (kDebugMode) {
        print('Avatar deleted successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to delete avatar: $e');
      }
    }
  }
}
