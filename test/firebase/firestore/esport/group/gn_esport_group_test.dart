import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';

// ignore: subtype_of_sealed_class
class _MockDoc extends Mock implements DocumentSnapshot<Object?> {}

void main() {
  group('GNEsportGroup.fromFirestore', () {
    test('document cũ còn esportId thừa vẫn parse được', () {
      final createdAt = DateTime(2026, 1, 1);
      final updatedAt = DateTime(2026, 1, 2);
      final doc = _MockDoc();
      when(() => doc.id).thenReturn('G1');
      when(() => doc.data()).thenReturn(<String, dynamic>{
        'esportId': 'pes',
        GNEsportGroup.groupNameKey: 'Nhóm PES',
        GNEsportGroup.ownerIdKey: 'owner',
        GNEsportGroup.membersKey: <String>['owner', 'u1'],
        GNEsportGroup.descriptionKey: 'desc',
        GNEsportGroup.createdAtKey: Timestamp.fromDate(createdAt),
        GNEsportGroup.updatedAtKey: Timestamp.fromDate(updatedAt),
        GNEsportGroup.statusKey: 'active',
      });

      final restored = GNEsportGroup.fromFirestore(doc);

      expect(restored.id, 'G1');
      expect(restored.groupName, 'Nhóm PES');
      expect(restored.ownerId, 'owner');
      expect(restored.members, ['owner', 'u1']);
      expect(restored.createdAt, createdAt);
      expect(restored.updatedAt, updatedAt);
    });

    test('parse deactivatedMembers khi có trong doc', () {
      final createdAt = DateTime(2026, 1, 1);
      final updatedAt = DateTime(2026, 1, 2);
      final doc = _MockDoc();
      when(() => doc.id).thenReturn('G1');
      when(() => doc.data()).thenReturn(<String, dynamic>{
        GNEsportGroup.groupNameKey: 'Nhóm PES',
        GNEsportGroup.ownerIdKey: 'owner',
        GNEsportGroup.membersKey: <String>['owner', 'u1', 'u2'],
        GNEsportGroup.deactivatedMembersKey: <String>['u2'],
        GNEsportGroup.descriptionKey: '',
        GNEsportGroup.createdAtKey: Timestamp.fromDate(createdAt),
        GNEsportGroup.updatedAtKey: Timestamp.fromDate(updatedAt),
        GNEsportGroup.statusKey: 'active',
      });

      final restored = GNEsportGroup.fromFirestore(doc);

      expect(restored.deactivatedMembers, ['u2']);
    });

    test('deactivatedMembers mặc định là [] khi field vắng mặt', () {
      final createdAt = DateTime(2026, 1, 1);
      final updatedAt = DateTime(2026, 1, 2);
      final doc = _MockDoc();
      when(() => doc.id).thenReturn('G1');
      when(() => doc.data()).thenReturn(<String, dynamic>{
        GNEsportGroup.groupNameKey: 'Nhóm PES',
        GNEsportGroup.ownerIdKey: 'owner',
        GNEsportGroup.membersKey: <String>['owner'],
        GNEsportGroup.descriptionKey: '',
        GNEsportGroup.createdAtKey: Timestamp.fromDate(createdAt),
        GNEsportGroup.updatedAtKey: Timestamp.fromDate(updatedAt),
        GNEsportGroup.statusKey: 'active',
      });

      final restored = GNEsportGroup.fromFirestore(doc);

      expect(restored.deactivatedMembers, isEmpty);
    });
  });

  group('GNEsportGroup.toFirestore', () {
    test('không ghi field esportId', () {
      final group = GNEsportGroup(
        id: 'G1',
        groupName: 'Nhóm PES',
        ownerId: 'owner',
        members: const ['owner'],
        description: '',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
        status: 'active',
      );

      final map = group.toFirestore();

      expect(map.containsKey('esportId'), isFalse);
      expect(map[GNEsportGroup.groupNameKey], 'Nhóm PES');
    });

    test('ghi deactivatedMembers vào map', () {
      final group = GNEsportGroup(
        id: 'G1',
        groupName: 'Nhóm PES',
        ownerId: 'owner',
        members: const ['owner', 'u2'],
        deactivatedMembers: const ['u2'],
        description: '',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
        status: 'active',
      );

      final map = group.toFirestore();

      expect(map[GNEsportGroup.deactivatedMembersKey], ['u2']);
    });
  });
}
