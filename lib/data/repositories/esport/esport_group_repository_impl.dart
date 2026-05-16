import 'package:pes_arena/domain/repositories/esport/esport_group_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_firestore_esport_group.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/injection_container.dart';

class EsportGroupRepositoryImpl implements EsportGroupRepository {
  @override
  Future<void> addMemberToGroup({
    required String groupId,
    required String memberId,
  }) {
    return getIt<GNFirestore>().addMemberToGroup(
      groupId: groupId,
      memberId: memberId,
    );
  }

  @override
  Future<GNEsportGroup> createEsportGroup({
    required String groupName,
    String description = '',
  }) {
    return getIt<GNFirestore>().createEsportGroup(
      groupName: groupName,
      description: description,
    );
  }

  @override
  Future<List<GNEsportGroup>> getEsportGroups() {
    return getIt<GNFirestore>().getEsportGroups();
  }

  @override
  Future<List<GNUser>> getMembersOfGroup(String groupId) {
    return getIt<GNFirestore>().getMembersOfGroup(groupId);
  }

  @override
  Future<List<GNEsportGroup>> getGroupsByOwnerId(String ownerId) {
    return getIt<GNFirestore>().getGroupsByOwnerId(ownerId);
  }

  @override
  Future<void> transferGroupOwnership({
    required String groupId,
    required String newOwnerId,
  }) async {
    final group = await getIt<GNFirestore>().getGroupById(groupId);
    if (group == null) {
      throw Exception('Group not found');
    }
    if (!group.members.contains(newOwnerId)) {
      throw Exception('New owner must be a group member');
    }
    return getIt<GNFirestore>().transferGroupOwnership(
      groupId: groupId,
      newOwnerId: newOwnerId,
    );
  }

  @override
  Future<void> deactivateGroup(String groupId) {
    return getIt<GNFirestore>().deactivateGroup(groupId);
  }

  @override
  Future<GNEsportGroup?> getGroup(String groupId) {
    return getIt<GNFirestore>().getGroupById(groupId);
  }

  @override
  Future<void> removeMemberFromGroup({
    required String groupId,
    required String memberId,
  }) {
    return getIt<GNFirestore>().removeMemberFromGroup(
      groupId: groupId,
      memberId: memberId,
    );
  }

  @override
  Future<void> toggleMemberDeactivation({
    required String groupId,
    required String userId,
    required bool deactivate,
  }) {
    return getIt<GNFirestore>().toggleMemberDeactivation(
      groupId: groupId,
      userId: userId,
      deactivate: deactivate,
    );
  }
}
