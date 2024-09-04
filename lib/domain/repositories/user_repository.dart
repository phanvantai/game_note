import 'package:game_note/firebase/firestore/user/user_model.dart';

abstract class UserRepository {
  Future<void> signOut();
  Future<void> deleteAccount();
  Future<UserModel> loadProfile();
}
