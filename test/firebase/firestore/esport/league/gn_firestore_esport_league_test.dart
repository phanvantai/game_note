import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_firestore_esport_league.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late GNFirestore fs;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fs = GNFirestore(fakeFirestore);
  });

  Future<void> createGroup(String id) async {
    await fakeFirestore.collection(GNEsportGroup.collectionName).doc(id).set({
      GNEsportGroup.groupNameKey: 'Group $id',
      GNEsportGroup.ownerIdKey: 'owner',
      GNEsportGroup.membersKey: ['owner', 'u1'],
      GNEsportGroup.deactivatedMembersKey: [],
      GNEsportGroup.descriptionKey: '',
      GNEsportGroup.createdAtKey: Timestamp.now(),
      GNEsportGroup.updatedAtKey: Timestamp.now(),
      GNEsportGroup.statusKey: 'active',
    });
  }

  Future<DocumentReference<Map<String, dynamic>>> createLeague({
    required String ownerId,
    bool isActive = true,
  }) async {
    await createGroup('G1');
    return fakeFirestore.collection(GNEsportLeague.collectionName).add({
      GNEsportLeague.fieldOwnerId: ownerId,
      GNEsportLeague.fieldGroupId: 'G1',
      GNEsportLeague.fieldName: 'League',
      GNEsportLeague.fieldStartDate: Timestamp.fromDate(DateTime(2026, 5, 10)),
      GNEsportLeague.fieldIsActive: isActive,
      GNEsportLeague.fieldDescription: '',
      GNEsportLeague.fieldParticipants: ['owner', 'u1'],
    });
  }

  test('getLeaguesByOwnerId returns active leagues owned by user', () async {
    await createLeague(ownerId: 'owner');
    await createLeague(ownerId: 'owner', isActive: false);
    await createLeague(ownerId: 'u2');

    final leagues = await fs.getLeaguesByOwnerId('owner');

    expect(leagues, hasLength(1));
    expect(leagues.single.ownerId, 'owner');
    expect(leagues.single.isActive, true);
    expect(leagues.single.group?.id, 'G1');
  });

  test('transferLeagueOwnership updates ownerId', () async {
    final ref = await createLeague(ownerId: 'owner');

    await fs.transferLeagueOwnership(leagueId: ref.id, newOwnerId: 'u1');

    final snap = await ref.get();
    expect(snap.data()?[GNEsportLeague.fieldOwnerId], 'u1');
  });
}
