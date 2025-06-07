import 'package:cloud_firestore/cloud_firestore.dart';

import '../../gn_firestore.dart';
import '../../user/gn_user.dart';
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

  Future<void> removeMemberFromGroup(
      {required String groupId, required String memberId}) async {
    final groupRef =
        firestore.collection(GNEsportGroup.collectionName).doc(groupId);
    final groupSnapshot = await groupRef.get();
    if (!groupSnapshot.exists) {
      throw Exception('Group not found');
    }
    await groupRef.update({
      GNEsportGroup.membersKey: FieldValue.arrayRemove([memberId]),
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

  // Batch load multiple groups to avoid N+1 query problem
  Future<Map<String, GNEsportGroup>> getGroupsById(
      List<String> groupIds) async {
    if (groupIds.isEmpty) return {};

    // Remove duplicates
    final uniqueGroupIds = groupIds.toSet().toList();

    // Firestore 'in' query supports up to 10 items, so we need to batch
    const batchSize = 10;
    Map<String, GNEsportGroup> groups = {};

    for (int i = 0; i < uniqueGroupIds.length; i += batchSize) {
      final batch = uniqueGroupIds.skip(i).take(batchSize).toList();

      final querySnapshot = await firestore
          .collection(GNEsportGroup.collectionName)
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      for (final doc in querySnapshot.docs) {
        groups[doc.id] = GNEsportGroup.fromFirestore(doc);
      }
    }

    return groups;
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

  // Fetch all members of a group
  Future<List<GNUser>> getMembersOfGroup(String groupId) async {
    final groupRef =
        firestore.collection(GNEsportGroup.collectionName).doc(groupId);
    final groupSnapshot = await groupRef.get();
    if (!groupSnapshot.exists) {
      throw Exception('Group not found');
    }
    final members = groupSnapshot.data()?[GNEsportGroup.membersKey] ?? [];
    final memberIds = members.cast<String>();
    final userSnapshots = await firestore
        .collection(GNUser.collectionName)
        .where(FieldPath.documentId, whereIn: memberIds)
        .get();
    return userSnapshots.docs.map((doc) => GNUser.fromFireStore(doc)).toList();
  }
}
