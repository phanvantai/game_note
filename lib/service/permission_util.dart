import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

class PermissionUtil {
  GNUser? _currentUser;

  void setCurrentUser(GNUser? user) {
    _currentUser = user;
  }

  bool get isAdmin => _currentUser?.isAdmin ?? false;
}
