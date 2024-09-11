import 'package:cloud_firestore/cloud_firestore.dart';

import '../../gn_firestore.dart';
import 'gn_esport_group.dart';

extension GNFirestoreEsportGroup on GNFirestore {
  // Fetch all esport groups status is active
  Future<List<GNEsportGroup>> getEsportGroups() async {
    QuerySnapshot snapshot = await firestore
        .collection(GNEsportGroup.collectionName)
        .where(GNEsportGroup.statusKey, isEqualTo: 'active')
        .get();
    return snapshot.docs
        .map((doc) => GNEsportGroup.fromFirestore(doc))
        .toList();
  }

  Future<GNEsportGroup> createEsportGroup({
    required String groupName,
    required String esportId,
    String description = '',
    required String location,
  }) async {
    final createdAt = DateTime.now();
    final updatedAt = createdAt;
    final data = {
      GNEsportGroup.esportIdKey: esportId,
      GNEsportGroup.groupNameKey: groupName,
      GNEsportGroup.ownerIdKey: currentUser.uid,
      GNEsportGroup.membersKey: [currentUser.uid],
      GNEsportGroup.descriptionKey: description,
      GNEsportGroup.createdAtKey: Timestamp.fromDate(createdAt),
      GNEsportGroup.updatedAtKey: Timestamp.fromDate(updatedAt),
      GNEsportGroup.statusKey: 'active',
      GNEsportGroup.locationKey: location,
    };
    final docRef =
        await firestore.collection(GNEsportGroup.collectionName).add(data);
    // Fetch the newly created group from Firestore
    DocumentSnapshot groupSnapshot = await docRef.get();
    return GNEsportGroup.fromFirestore(groupSnapshot);
  }

  Future<void> addMemberToGroup(
      {required String groupId, required String memberId}) async {
    final groupRef =
        firestore.collection(GNEsportGroup.collectionName).doc(groupId);
    final groupSnapshot = await groupRef.get();
    if (!groupSnapshot.exists) {
      throw Exception('Group not found');
    }
    await groupRef.update({
      GNEsportGroup.membersKey: FieldValue.arrayUnion([memberId]),
      GNEsportGroup.updatedAtKey: Timestamp.now(),
    });
  }

  // Fetch a group by its ID
  Future<GNEsportGroup?> getGroupById(String groupId) async {
    final DocumentSnapshot docSnapshot = await firestore
        .collection(GNEsportGroup.collectionName)
        .doc(groupId)
        .get();

    if (docSnapshot.exists) {
      return GNEsportGroup.fromFirestore(docSnapshot);
    }
    return null;
  }

  // Update group information (optional utility)
  Future<void> updateGroup(GNEsportGroup group) async {
    await firestore
        .collection(GNEsportGroup.collectionName)
        .doc(group.id)
        .update(group.toFirestore());
  }

  // Deactivate a group (set status to 'inactive')
  Future<void> deactivateGroup(String groupId) async {
    await firestore
        .collection(GNEsportGroup.collectionName)
        .doc(groupId)
        .update({
      GNEsportGroup.statusKey: 'inactive',
      GNEsportGroup.updatedAtKey:
          Timestamp.now(), // Update the last modified timestamp
    });
  }

  // Activate a group (set status to 'active')
  Future<void> activateGroup(String groupId) async {
    await firestore
        .collection(GNEsportGroup.collectionName)
        .doc(groupId)
        .update({
      GNEsportGroup.statusKey: 'active',
      GNEsportGroup.updatedAtKey: Timestamp.now(),
    });
  }
}
