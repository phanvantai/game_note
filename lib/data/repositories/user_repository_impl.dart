import 'package:game_note/domain/repositories/user_repository.dart';
import 'package:game_note/firebase/firestore/user/gn_firestore_user.dart';
import 'package:game_note/firebase/firestore/user/user_model.dart';
import 'package:game_note/injection_container.dart';

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
}
