import 'package:pes_arena/api/api_client.dart';
import 'package:pes_arena/api/api_json.dart';
import 'package:pes_arena/domain/repositories/esport/esport_group_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

/// [EsportGroupRepository] backed by the Game Note REST API. Permission rules
/// (owner-only actions, member-only adds) are enforced server-side.
class ApiEsportGroupRepository implements EsportGroupRepository {
  ApiEsportGroupRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  String _group(String groupId) => '/v1/groups/$groupId';

  List<GNEsportGroup> _groups(Object? json) =>
      apiMapList(json).map(GNEsportGroup.fromApi).toList();

  @override
  Future<List<GNEsportGroup>> getEsportGroups() async =>
      _groups(await _client.get('/v1/groups'));

  @override
  Future<List<GNEsportGroup>> getGroupsByOwnerId(String ownerId) async =>
      _groups(await _client.get('/v1/groups', query: {'ownerId': ownerId}));

  @override
  Future<GNEsportGroup> createEsportGroup({
    required String groupName,
    String description = '',
  }) async {
    final json = await _client.post(
      '/v1/groups',
      body: {'groupName': groupName, 'description': description},
    );
    return GNEsportGroup.fromApi(json as Map<String, dynamic>);
  }

  @override
  Future<GNEsportGroup?> getGroup(String groupId) async {
    try {
      final json = await _client.get(_group(groupId));
      return GNEsportGroup.fromApi(json as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  @override
  Future<List<GNUser>> getMembersOfGroup(String groupId) async => apiMapList(
    await _client.get('${_group(groupId)}/members'),
  ).map(GNUser.fromApi).toList();

  @override
  Future<void> addMemberToGroup({
    required String groupId,
    required String memberId,
  }) => _client.post('${_group(groupId)}/members', body: {'userId': memberId});

  @override
  Future<void> removeMemberFromGroup({
    required String groupId,
    required String memberId,
  }) => _client.delete('${_group(groupId)}/members/$memberId');

  @override
  Future<void> toggleMemberDeactivation({
    required String groupId,
    required String userId,
    required bool deactivate,
  }) => _client.put(
    '${_group(groupId)}/members/$userId/deactivation',
    body: {'deactivated': deactivate},
  );

  @override
  Future<void> transferGroupOwnership({
    required String groupId,
    required String newOwnerId,
  }) => _client.post(
    '${_group(groupId)}/transfer-ownership',
    body: {'newOwnerId': newOwnerId},
  );

  @override
  Future<void> deactivateGroup(String groupId) =>
      _client.post('${_group(groupId)}/deactivate');

  /// The backend deletes the group and everything under it synchronously,
  /// replacing the old `group_deletion_requests` Cloud Function flow.
  @override
  Future<void> requestDeleteGroup(String groupId) =>
      _client.delete(_group(groupId));
}
