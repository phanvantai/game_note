import 'package:pes_arena/firebase/firestore/team/gn_team.dart';

abstract class TeamRepository {
  Future<void> createTeam();
  Future<void> deleteTeam();
  Future<void> updateTeam();
  Future<void> joinTeam();
  Future<void> leaveTeam();
  Future<List<GNTeam>> getMyTeams();
  Future<List<GNTeam>> getOtherTeams();
}
