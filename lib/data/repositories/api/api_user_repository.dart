import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pes_arena/api/api_client.dart';
import 'package:pes_arena/api/api_json.dart';
import 'package:pes_arena/domain/repositories/user_repository.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

import 'api_esport_league_repository.dart' show fetchUsersByIds;

/// Picks an avatar image; returns null when the user cancels.
typedef AvatarPicker = Future<XFile?> Function();

/// [UserRepository] backed by the Game Note REST API. Sign-in, sign-out,
/// password changes and the Firebase Auth profile stay on [GNAuth].
class ApiUserRepository implements UserRepository {
  ApiUserRepository({
    required ApiClient client,
    required GNAuth auth,
    AvatarPicker? pickAvatar,
  }) : _client = client,
       _auth = auth,
       _pickAvatar = pickAvatar ?? _pickFromGallery;

  static const int maxAvatarBytes = 5 * 1024 * 1024;

  final ApiClient _client;
  final GNAuth _auth;
  final AvatarPicker _pickAvatar;

  // coverage:ignore-start
  static Future<XFile?> _pickFromGallery() =>
      ImagePicker().pickImage(source: ImageSource.gallery);
  // coverage:ignore-end

  GNUser _user(Object? json) => GNUser.fromApi(json as Map<String, dynamic>);

  List<GNUser> _users(Object? json) =>
      apiMapList(json).map(GNUser.fromApi).toList();

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> changePassword(String oldPassword, String newPassword) =>
      _auth.changePassword(oldPassword, newPassword);

  @override
  Future<GNUser> ensureCurrentUser(User firebaseUser) async => _user(
    await _client.post(
      '/v1/me/bootstrap',
      body: {
        'displayName': firebaseUser.displayName,
        'email': firebaseUser.email,
        'phoneNumber': firebaseUser.phoneNumber,
        'photoUrl': firebaseUser.photoURL,
      },
    ),
  );

  @override
  Future<GNUser> loadProfile() async => _user(await _client.get('/v1/me'));

  @override
  Future<GNUser?> getUser(String userId) async {
    try {
      return _user(await _client.get('/v1/users/$userId'));
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  @override
  Future<Map<String, GNUser>> getUsersByIds(List<String> userIds) =>
      fetchUsersByIds(_client, userIds);

  @override
  Future<GNUser> createPlaceholderUser({required String displayName}) async =>
      _user(
        await _client.post(
          '/v1/users/placeholders',
          body: {'displayName': displayName},
        ),
      );

  @override
  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? email,
  }) async {
    bool present(String? v) => v != null && v.isNotEmpty;
    await _client.patch(
      '/v1/me',
      body: {
        if (present(displayName)) 'displayName': displayName,
        if (present(phoneNumber)) 'phoneNumber': phoneNumber,
        if (present(email)) 'email': email,
      },
    );
    if (present(displayName)) {
      await _auth.currentUser?.updateDisplayName(displayName);
    }
  }

  /// Soft-deletes the profile on the backend, then the Firebase account.
  @override
  Future<void> deleteAccount() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) throw Exception('User is not signed in');
    await _client.delete('/v1/me');
    await firebaseUser.delete();
  }

  @override
  Future<void> changeAvatar() async {
    final picked = await _pickAvatar();
    if (picked == null) return;
    if (await picked.length() > maxAvatarBytes) {
      throw Exception('Kích thước file phải nhỏ hơn 5MB');
    }
    final user = _user(
      await _client.putMultipart(
        '/v1/me/avatar',
        field: 'file',
        bytes: await picked.readAsBytes(),
        filename: picked.name.isEmpty ? 'avatar.jpg' : picked.name,
      ),
    );
    await _auth.currentUser?.updatePhotoURL(user.photoUrl);
  }

  @override
  Future<void> deleteAvatar() async {
    await _client.delete('/v1/me/avatar');
    await _auth.currentUser?.updatePhotoURL(null);
  }

  @override
  Future<List<GNUser>> searchUser(String query) async =>
      _users(await _client.get('/v1/users/search', query: {'q': query}));

  @override
  Future<List<GNUser>> searchUserByGroup(String groupId, String query) async =>
      _users(
        await _client.get(
          '/v1/users/search',
          query: {'q': query, 'groupId': groupId},
        ),
      );
}
