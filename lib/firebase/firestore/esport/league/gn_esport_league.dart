import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class GNEsportLeague extends Equatable {
  final String id; // league id
  final String groupId; // id of the group this league belongs to
  final String name; // league name
  final DateTime startDate; // start date of the league
  final DateTime? endDate; // end date of the league (nullable)
  final bool isFinished; // whether the league is finished
  final String description; // league description
  final List<String> participants; // list of participants

  static const String collectionName = 'esports_leagues';

  static const String fieldId = 'id';
  static const String fieldGroupId = 'groupId';
  static const String fieldName = 'name';
  static const String fieldStartDate = 'startDate';
  static const String fieldEndDate = 'endDate';
  static const String fieldIsFinished = 'isFinished';
  static const String fieldDescription = 'description';
  static const String fieldParticipants = 'participants';

  const GNEsportLeague({
    required this.id,
    required this.groupId,
    required this.name,
    required this.startDate,
    this.endDate,
    required this.isFinished,
    required this.description,
    required this.participants,
  });

  @override
  List<Object?> get props => [
        id,
        groupId,
        name,
        startDate,
        endDate,
        isFinished,
        description,
        participants,
      ];

  GNEsportLeague copyWith({
    String? id,
    String? groupId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isFinished,
    String? description,
    List<String>? participants,
  }) {
    return GNEsportLeague(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isFinished: isFinished ?? this.isFinished,
      description: description ?? this.description,
      participants: participants ?? this.participants,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      fieldGroupId: groupId,
      fieldName: name,
      fieldStartDate: Timestamp.fromDate(startDate),
      if (endDate != null) fieldEndDate: Timestamp.fromDate(endDate!),
      fieldIsFinished: isFinished,
      fieldDescription: description,
      fieldParticipants: participants,
    };
  }

  factory GNEsportLeague.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GNEsportLeague(
      id: doc.id, // league id
      groupId: data[fieldGroupId],
      name: data[fieldName],
      startDate: (data[fieldStartDate] as Timestamp).toDate(),
      endDate: data[fieldEndDate] != null
          ? (data[fieldEndDate] as Timestamp).toDate()
          : null,
      isFinished: data[fieldIsFinished],
      description: data[fieldDescription],
      participants: List<String>.from(data[fieldParticipants] ?? []),
    );
  }
}
