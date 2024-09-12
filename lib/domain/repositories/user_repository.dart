import 'package:game_note/firebase/firestore/user/gn_user.dart';

abstract class UserRepository {
  Future<void> signOut();
  Future<void> deleteAccount();
  Future<GNUser> loadProfile();

  Future<void> changeAvatar();
  Future<void> deleteAvatar();
}
