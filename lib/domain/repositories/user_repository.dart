import 'package:firebase_auth/firebase_auth.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

abstract class UserRepository {
  Future<void> signOut();
  Future<void> deleteAccount();
  Future<GNUser> loadProfile();

  /// Returns the profile for a freshly signed-in Firebase user, creating it
  /// from [firebaseUser]'s auth profile on first sign-in.
  Future<GNUser> ensureCurrentUser(User firebaseUser);

  Future<GNUser?> getUser(String userId);

  /// Users keyed by id; unknown ids are omitted.
  Future<Map<String, GNUser>> getUsersByIds(List<String> userIds);

  /// Creates an offline "placeholder" player that can join groups.
  Future<GNUser> createPlaceholderUser({required String displayName});

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
