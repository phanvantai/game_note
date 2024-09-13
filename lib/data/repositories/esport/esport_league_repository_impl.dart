import 'package:game_note/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:game_note/firebase/firestore/esport/league/gn_firestore_esport_league.dart';
import 'package:game_note/injection_container.dart';

import '../../../domain/repositories/esport/esport_league_repository.dart';
import '../../../firebase/firestore/gn_firestore.dart';

class EsportLeagueRepositoryImpl implements EsportLeagueRepository {
  @override
  Future<void> addLeague({
    required String name,
    required String groupId,
    DateTime? startDate,
    DateTime? endDate,
    String description = '',
  }) {
    return getIt<GNFirestore>().addLeague(
      name: name,
      groupId: groupId,
      startDate: startDate,
      endDate: endDate,
      description: description,
    );
  }

  @override
  Future<GNEsportLeague?> getLeague(String leagueId) {
    return getIt<GNFirestore>().getLeague(leagueId);
  }

  @override
  Future<List<GNEsportLeague>> getLeagues() {
    return getIt<GNFirestore>().getLeagues();
  }
}
