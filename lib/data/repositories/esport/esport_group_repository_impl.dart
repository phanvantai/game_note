import 'package:game_note/domain/repositories/esport/esport_group_repository.dart';
import 'package:game_note/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:game_note/firebase/firestore/esport/group/gn_firestore_esport_group.dart';
import 'package:game_note/firebase/firestore/gn_firestore.dart';
import 'package:game_note/firebase/firestore/user/gn_user.dart';
import 'package:game_note/injection_container.dart';

class EsportGroupRepositoryImpl implements EsportGroupRepository {
  @override
  Future<void> addMemberToGroup(
      {required String groupId, required String memberId}) {
    return getIt<GNFirestore>()
        .addMemberToGroup(groupId: groupId, memberId: memberId);
  }

  @override
  Future<GNEsportGroup> createEsportGroup({
    required String groupName,
    required String esportId,
    String description = '',
    required String location,
  }) {
    return getIt<GNFirestore>().createEsportGroup(
      groupName: groupName,
      esportId: esportId,
      description: description,
      location: location,
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
  Future<GNEsportGroup?> getGroup(String groupId) {
    return getIt<GNFirestore>().getGroupById(groupId);
  }

  @override
  Future<void> removeMemberFromGroup(
      {required String groupId, required String memberId}) {
    return getIt<GNFirestore>()
        .removeMemberFromGroup(groupId: groupId, memberId: memberId);
  }
}
