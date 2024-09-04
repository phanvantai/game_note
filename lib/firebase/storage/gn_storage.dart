import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class GNStorage {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  FirebaseStorage get storage => _storage;

  Future<String> uploadAvatarFile(String filePath) async {
    // Create a reference to the file in Firebase Storage
    Reference storageRef = _storage.ref().child('avatars/your_file_name');

    // Upload the file to Firebase Storage
    TaskSnapshot snapshot = await storageRef.putFile(File(filePath));

    // Get the download URL of the uploaded file
    String downloadURL = await snapshot.ref.getDownloadURL();

    // Return the download URL
    return downloadURL;
  }
}
