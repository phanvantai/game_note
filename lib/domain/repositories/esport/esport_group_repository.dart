import 'package:game_note/firebase/firestore/user/gn_user.dart';

import '../../../firebase/firestore/esport/group/gn_esport_group.dart';

abstract class EsportGroupRepository {
  Future<List<GNEsportGroup>> getEsportGroups();

  Future<GNEsportGroup> createEsportGroup({
    required String groupName,
    required String esportId,
    String description = '',
    required String location,
  });

  Future<void> addMemberToGroup({
    required String groupId,
    required String memberId,
  });

  Future<GNEsportGroup?> getGroup(String groupId);

  Future<List<GNUser>> getMembersOfGroup(String groupId);

  Future<void> removeMemberFromGroup({
    required String groupId,
    required String memberId,
  });
}
