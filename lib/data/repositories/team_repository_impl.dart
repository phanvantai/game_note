import 'package:pes_arena/domain/repositories/team_repository.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/firebase/firestore/team/gn_firestore_team.dart';
import 'package:pes_arena/firebase/firestore/team/gn_team.dart';
import 'package:pes_arena/injection_container.dart';

class TeamRepositoryImpl implements TeamRepository {
  @override
  Future<void> createTeam() {
    // TODO: implement createTeam
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTeam() {
    // TODO: implement deleteTeam
    throw UnimplementedError();
  }

  @override
  Future<List<GNTeam>> getMyTeams() async {
    final firestore = getIt<GNFirestore>();
    return firestore.getTeamsByUser(firestore.currentUser.uid);
  }

  @override
  Future<List<GNTeam>> getOtherTeams() {
    final firestore = getIt<GNFirestore>();
    return firestore.getTeams();
  }

  @override
  Future<void> joinTeam() {
    // TODO: implement joinTeam
    throw UnimplementedError();
  }

  @override
  Future<void> leaveTeam() {
    // TODO: implement leaveTeam
    throw UnimplementedError();
  }

  @override
  Future<void> updateTeam() {
    // TODO: implement updateTeam
    throw UnimplementedError();
  }
}
