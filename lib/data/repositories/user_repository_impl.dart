import 'package:game_note/domain/repositories/user_repository.dart';
import 'package:game_note/firebase/firestore/user/gn_firestore_user.dart';
import 'package:game_note/firebase/firestore/user/gn_user.dart';
import 'package:game_note/injection_container.dart';
import 'package:image_picker/image_picker.dart';

import '../../firebase/auth/gn_auth.dart';
import '../../firebase/firestore/gn_firestore.dart';

class UserRepositoryImpl implements UserRepository {
  @override
  Future<void> deleteAccount() async {
    return getIt<GNFirestore>().deleteCurrentUser();
  }

  @override
  Future<GNUser> loadProfile() async {
    return getIt<GNFirestore>().getCurrentUser();
  }

  @override
  Future<void> signOut() async {
    return getIt<GNAuth>().signOut();
  }

  @override
  Future<void> changeAvatar() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      return;
    }
    final fileSize = await pickedFile.length();
    if (fileSize > 5 * 1024 * 1024) {
      throw Exception('Kích thước file phải nhỏ hơn 5MB');
    }
    return getIt<GNFirestore>().changeAvatar(pickedFile);
  }

  @override
  Future<void> deleteAvatar() async {
    return getIt<GNFirestore>().deleteAvatar();
  }

  @override
  Future<List<GNUser>> searchUser(String query) {
    return getIt<GNFirestore>().searchUser(query);
  }

  @override
  Future<List<GNUser>> searchUserByGroup(String groupId, String query) {
    return getIt<GNFirestore>().searchUserByGroup(groupId, query);
  }

  @override
  Future<void> updateProfile(
      {String? displayName, String? phoneNumber, String? email}) {
    return getIt<GNFirestore>().updateProfile(
      displayName: displayName,
      phoneNumber: phoneNumber,
      email: email,
    );
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) {
    return getIt<GNAuth>().changePassword(oldPassword, newPassword);
  }

  @override
  Future<GNUser?> getUser(String userId) {
    return getIt<GNFirestore>().getUserById(userId);
  }
}
