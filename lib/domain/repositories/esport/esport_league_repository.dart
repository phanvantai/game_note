import '../../../firebase/firestore/esport/league/gn_esport_league.dart';

abstract class EsportLeagueRepository {
  Future<List<GNEsportLeague>> getLeagues();

  Future<GNEsportLeague?> getLeague(String leagueId);

  Future<void> addLeague({
    required String name,
    required String groupId,
    DateTime? startDate,
    DateTime? endDate,
    String description = '',
  });
}
