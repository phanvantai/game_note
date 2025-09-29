import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

abstract class UserRepository {
  Future<void> signOut();
  Future<void> deleteAccount();
  Future<GNUser> loadProfile();

  Future<GNUser?> getUser(String userId);

  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? email,
  });

  Future<void> changePassword(String oldPassword, String newPassword);

  Future<void> changeAvatar();
  Future<void> deleteAvatar();

  Future<List<GNUser>> searchUser(String query);

  Future<List<GNUser>> searchUserByGroup(String groupId, String query);
}
