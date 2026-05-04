// Pure adapter: wraps `GNFirestore` extension methods (which can't be mocked
// because they're extension methods on a final class).
//
// Excluded from coverage gate per CLAUDE.md "ad/firebase glue" exemption —
// the unit-testable logic lives in [OfflineToOnlineMigrator] / [MigrationPlan].
//
// coverage:ignore-file

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pes_arena/data/sync/migration_plan.dart';
import 'package:pes_arena/data/sync/sync_remote_gateway.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_firestore_esport_group.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/firebase/gn_collection.dart';

class SyncRemoteGatewayImpl implements SyncRemoteGateway {
  SyncRemoteGatewayImpl(this._firestoreWrapper);
  final GNFirestore _firestoreWrapper;

  FirebaseFirestore get _db => _firestoreWrapper.firestore;

  @override
  Future<List<GNEsportGroup>> getMyGroups() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const [];
    final snapshot = await _db
        .collection(GNEsportGroup.collectionName)
        .where(GNEsportGroup.membersKey, arrayContains: uid)
        .where(GNEsportGroup.statusKey, isEqualTo: 'active')
        .get();
    return snapshot.docs
        .map((doc) => GNEsportGroup.fromFirestore(doc))
        .toList();
  }

  @override
  Future<List<GNUser>> getGroupMembers(String groupId) {
    return _firestoreWrapper.getMembersOfGroup(groupId);
  }

  @override
  Future<void> commitBatch(MigrationPlan plan) async {
    if (kDebugMode) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '<null>';
      debugPrint('[sync.commit] uid=$uid groupId=${plan.groupId} '
          'leagueId=${plan.leagueId} totalOps=${plan.totalOps} '
          'placeholders=${plan.placeholderUsers.length} '
          'addToGroup=${plan.uidsToAddToGroup} '
          'participants=${plan.participantUids.length} '
          'stats=${plan.statDocs.length} matches=${plan.matches.length}');
    }
    final batch = _db.batch();

    // Placeholder users.
    for (final p in plan.placeholderUsers) {
      final ref = _db.collection(GNUser.collectionName).doc(p.id);
      batch.set(ref, {
        GNUser.displayNameKey: p.displayName,
        GNUser.phoneNumberKey: null,
        GNUser.emailKey: null,
        GNUser.photoUrlKey: null,
        GNUser.roleKey: 'user',
        GNUser.fcmTokenKey: '',
        GNUser.isPlaceholderKey: true,
        GNCommonFields.createdAt: FieldValue.serverTimestamp(),
        GNCommonFields.updatedAt: FieldValue.serverTimestamp(),
      });
    }

    // Add to group.members. arrayUnion idempotent so safe even if some uids
    // already there.
    if (plan.uidsToAddToGroup.isNotEmpty) {
      batch.update(
        _db.collection(GNEsportGroup.collectionName).doc(plan.groupId),
        {
          GNEsportGroup.membersKey: FieldValue.arrayUnion(plan.uidsToAddToGroup),
          GNEsportGroup.updatedAtKey: Timestamp.now(),
        },
      );
    }

    // League doc.
    batch.set(
      _db.collection(GNEsportLeague.collectionName).doc(plan.leagueId),
      {
        ...plan.leagueData,
        GNEsportLeague.fieldParticipants: plan.participantUids,
      },
    );

    // Stat docs (zero-init or pre-computed totals from offline matches).
    for (final s in plan.statDocs) {
      final ref = _db
          .collection(GNEsportLeague.collectionName)
          .doc(plan.leagueId)
          .collection(GNEsportLeagueStat.collectionName)
          .doc(s.id);
      batch.set(ref, {
        GNEsportLeagueStat.fieldUserId: s.userId,
        GNEsportLeagueStat.fieldLeagueId: plan.leagueId,
        GNEsportLeagueStat.fieldMatchesPlayed: s.matchesPlayed,
        GNEsportLeagueStat.fieldGoals: s.goals,
        GNEsportLeagueStat.fieldGoalsConceded: s.goalsConceded,
        GNEsportLeagueStat.fieldWins: s.wins,
        GNEsportLeagueStat.fieldDraws: s.draws,
        GNEsportLeagueStat.fieldLosses: s.losses,
      });
    }

    // Match docs.
    for (final m in plan.matches) {
      final ref = _db
          .collection(GNEsportLeague.collectionName)
          .doc(plan.leagueId)
          .collection(GNEsportMatch.collectionName)
          .doc(m.id);
      batch.set(ref, {
        ...m.toMap(),
        GNEsportMatch.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
    }

    try {
      await batch.commit();
      if (kDebugMode) {
        debugPrint('[sync.commit] OK leagueId=${plan.leagueId}');
      }
    } on FirebaseException catch (e, st) {
      if (kDebugMode) {
        debugPrint('[sync.commit] FAILED code=${e.code} message=${e.message} '
            'plugin=${e.plugin}');
        debugPrint('[sync.commit] groupId=${plan.groupId} '
            'placeholderIds=${plan.placeholderUsers.map((p) => p.id).toList()} '
            'leagueId=${plan.leagueId} '
            'addToGroup=${plan.uidsToAddToGroup}');
        debugPrint('$st');
      }
      rethrow;
    }
  }
}
