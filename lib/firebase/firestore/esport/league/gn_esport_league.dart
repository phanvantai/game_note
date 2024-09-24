import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../group/gn_esport_group.dart';

enum GNEsportLeagueStatus { upcoming, ongoing, finished }

extension GNEsportLeagueStatusExtension on GNEsportLeagueStatus {
  String get value {
    switch (this) {
      case GNEsportLeagueStatus.upcoming:
        return 'upcoming';
      case GNEsportLeagueStatus.ongoing:
        return 'ongoing';
      case GNEsportLeagueStatus.finished:
        return 'finished';
    }
  }

  String get name {
    switch (this) {
      case GNEsportLeagueStatus.upcoming:
        return 'Sắp diễn ra';
      case GNEsportLeagueStatus.ongoing:
        return 'Đang diễn ra';
      case GNEsportLeagueStatus.finished:
        return 'Đã kết thúc';
    }
  }

  Color get color {
    switch (this) {
      case GNEsportLeagueStatus.upcoming:
        return Colors.green[300]!;
      case GNEsportLeagueStatus.ongoing:
        return Colors.orange[300]!;
      case GNEsportLeagueStatus.finished:
        return Colors.red[300]!;
    }
  }

  static GNEsportLeagueStatus fromString(String? status) {
    switch (status) {
      case 'upcoming':
        return GNEsportLeagueStatus.upcoming;
      case 'ongoing':
        return GNEsportLeagueStatus.ongoing;
      case 'finished':
        return GNEsportLeagueStatus.finished;
      default:
        return GNEsportLeagueStatus.upcoming;
    }
  }
}

class GNEsportLeague extends Equatable {
  final String id; // league id
  final String ownerId; // owner id of the league
  final String groupId; // id of the group this league belongs to
  final String name; // league name
  final DateTime startDate; // start date of the league
  final DateTime? endDate; // end date of the league (nullable)
  final bool isActive; // whether the league is active or not
  final String description; // league description
  final List<String> participants; // list of participants
  final GNEsportGroup? group; // group this league belongs to
  final String? status; // status of the league: upcoming, ongoing, finished

  // esport_leagues is a top-level collection
  // esports_leagues/{leagueId}
  static const String collectionName = 'esports_leagues';

  static const String fieldId = 'id';
  static const String fieldOwnerId = 'ownerId';
  static const String fieldGroupId = 'groupId';
  static const String fieldName = 'name';
  static const String fieldStartDate = 'startDate';
  static const String fieldEndDate = 'endDate';
  static const String fieldIsActive = 'isActive';
  static const String fieldDescription = 'description';
  static const String fieldParticipants = 'participants';
  static const String fieldStatus = 'status';

  const GNEsportLeague({
    required this.id,
    required this.ownerId,
    required this.groupId,
    required this.name,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.description,
    required this.participants,
    this.group,
    this.status,
  });

  @override
  List<Object?> get props => [
        id,
        ownerId,
        groupId,
        name,
        startDate,
        endDate,
        isActive,
        description,
        participants,
        status,
        group,
      ];

  GNEsportLeague copyWith({
    String? id,
    String? ownerId,
    String? groupId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? description,
    List<String>? participants,
    GNEsportGroup? group,
    String? status,
  }) {
    return GNEsportLeague(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      participants: participants ?? this.participants,
      group: group ?? this.group,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      fieldGroupId: groupId,
      fieldOwnerId: ownerId,
      fieldName: name,
      fieldStartDate: Timestamp.fromDate(startDate),
      if (endDate != null) fieldEndDate: Timestamp.fromDate(endDate!),
      fieldIsActive: isActive,
      fieldDescription: description,
      fieldParticipants: participants,
      fieldStatus: status,
    };
  }

  factory GNEsportLeague.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GNEsportLeague(
      id: doc.id, // league id
      ownerId: data[fieldOwnerId] ?? '', // owner id of the league
      groupId: data[fieldGroupId],
      name: data[fieldName],
      startDate: (data[fieldStartDate] as Timestamp).toDate(),
      endDate: data[fieldEndDate] != null
          ? (data[fieldEndDate] as Timestamp).toDate()
          : null,
      isActive: data[fieldIsActive] ?? true,
      description: data[fieldDescription],
      participants: List<String>.from(data[fieldParticipants] ?? []),
      status: data[fieldStatus] ?? 'upcoming',
    );
  }
}
