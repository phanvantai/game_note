import 'package:game_note/domain/repositories/user_repository.dart';
import 'package:game_note/firebase/firestore/user/gn_firestore_user.dart';
import 'package:game_note/firebase/firestore/user/user_model.dart';
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
  Future<UserModel> loadProfile() async {
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
}
