import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class GNEsportGroup extends Equatable {
  final String id; // This is the group document ID
  final String groupName;
  final String ownerId;
  final List<String> members;
  final List<String> deactivatedMembers;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status; // active or inactive

  const GNEsportGroup({
    required this.id,
    required this.groupName,
    required this.ownerId,
    required this.members,
    this.deactivatedMembers = const [],
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
  });

  GNEsportGroup copyWith({
    String? groupName,
    String? ownerId,
    List<String>? members,
    List<String>? deactivatedMembers,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
  }) {
    return GNEsportGroup(
      id: id,
      groupName: groupName ?? this.groupName,
      ownerId: ownerId ?? this.ownerId,
      members: members ?? this.members,
      deactivatedMembers: deactivatedMembers ?? this.deactivatedMembers,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupName,
    ownerId,
    members,
    deactivatedMembers,
    description,
    // createdAt,
    // updatedAt,
    status,
  ];

  // Factory method to convert Firestore document into GNEsportGroup object
  factory GNEsportGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GNEsportGroup(
      id: doc.id,
      groupName: data[groupNameKey] ?? '',
      ownerId: data[ownerIdKey] ?? '',
      members: List<String>.from(data[membersKey] ?? []),
      deactivatedMembers: List<String>.from(data[deactivatedMembersKey] ?? []),
      description: data[descriptionKey] ?? '',
      createdAt: (data[createdAtKey] as Timestamp).toDate(),
      updatedAt: (data[updatedAtKey] as Timestamp).toDate(),
      status: data[statusKey] ?? 'active',
    );
  }

  // Convert object to JSON format for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      groupNameKey: groupName,
      ownerIdKey: ownerId,
      membersKey: members,
      deactivatedMembersKey: deactivatedMembers,
      descriptionKey: description,
      createdAtKey: Timestamp.fromDate(createdAt),
      updatedAtKey: Timestamp.fromDate(updatedAt),
      statusKey: status,
    };
  }

  // Creates a minimal placeholder used when only the group ID is known
  // (e.g. direct URL access). Real data is fetched via GetGroupDetail.
  factory GNEsportGroup.placeholder(String id) {
    final now = DateTime.fromMillisecondsSinceEpoch(0);
    return GNEsportGroup(
      id: id,
      groupName: '',
      ownerId: '',
      members: const [],
      description: '',
      createdAt: now,
      updatedAt: now,
      status: 'active',
    );
  }

  // key-value pairs of the object
  static const String groupNameKey = 'groupName';
  static const String ownerIdKey = 'ownerId';
  static const String membersKey = 'members';
  static const String deactivatedMembersKey = 'deactivatedMembers';
  static const String descriptionKey = 'description';
  static const String createdAtKey = 'createdAt';
  static const String updatedAtKey = 'updatedAt';
  static const String statusKey = 'status';

  static const String collectionName = 'esports_groups';
}
