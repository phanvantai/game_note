import 'package:cloud_firestore/cloud_firestore.dart';

class GNEsportGroup {
  final String id; // This is the group document ID
  final String esportId;
  final String groupName;
  final String ownerId;
  final List<String> members;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status; // active or inactive
  final String location;

  GNEsportGroup({
    required this.id,
    required this.esportId,
    required this.groupName,
    required this.ownerId,
    required this.members,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.location,
  });

  GNEsportGroup copyWith({
    String? groupName,
    String? ownerId,
    List<String>? members,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? location,
  }) {
    return GNEsportGroup(
      id: id,
      esportId: esportId,
      groupName: groupName ?? this.groupName,
      ownerId: ownerId ?? this.ownerId,
      members: members ?? this.members,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      location: location ?? this.location,
    );
  }

  // Factory method to convert Firestore document into GNEsportGroup object
  factory GNEsportGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GNEsportGroup(
      id: doc.id,
      esportId: data[esportIdKey] ?? '',
      groupName: data[groupNameKey] ?? '',
      ownerId: data[ownerIdKey] ?? '',
      members: List<String>.from(data[membersKey] ?? []),
      description: data[descriptionKey] ?? '',
      createdAt: (data[createdAtKey] as Timestamp).toDate(),
      updatedAt: (data[updatedAtKey] as Timestamp).toDate(),
      status: data[statusKey] ?? 'active',
      location: data[locationKey] ?? '',
    );
  }

  // Convert object to JSON format for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      esportIdKey: esportId,
      groupNameKey: groupName,
      ownerIdKey: ownerId,
      membersKey: members,
      descriptionKey: description,
      createdAtKey: Timestamp.fromDate(createdAt),
      updatedAtKey: Timestamp.fromDate(updatedAt),
      statusKey: status,
      locationKey: location,
    };
  }

  // key-value pairs of the object
  static const String esportIdKey = 'esportId';
  static const String groupNameKey = 'groupName';
  static const String ownerIdKey = 'ownerId';
  static const String membersKey = 'members';
  static const String descriptionKey = 'description';
  static const String createdAtKey = 'createdAt';
  static const String updatedAtKey = 'updatedAt';
  static const String statusKey = 'status';
  static const String locationKey = 'location';

  static const String collectionName = 'esports_groups';
}
