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
}
