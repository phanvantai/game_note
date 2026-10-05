import 'package:pes_arena/api/api_client.dart';
import 'package:pes_arena/domain/repositories/esport/esport_group_stats_repository.dart';
import 'package:pes_arena/domain/repositories/user_stats_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/group/stats/gn_esport_group_stats_summary.dart';
import 'package:pes_arena/firebase/firestore/user/stats/gn_user_h2h.dart';
import 'package:pes_arena/firebase/firestore/user/stats/gn_user_stats_summary.dart';

/// [UserStatsRepository] backed by the Game Note REST API. The backend
/// computes the summary from matches on every request, so it is never stale.
class ApiUserStatsRepository implements UserStatsRepository {
  ApiUserStatsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  @override
  Future<GNUserStatsSummary?> getSummary(String uid) async {
    final json = await _client.get('/v1/users/$uid/summary');
    return GNUserStatsSummary.fromApi(json as Map<String, dynamic>);
  }

  @override
  Future<GNUserH2H?> getH2H({
    required String uid,
    required String opponentUid,
  }) async {
    try {
      final json = await _client.get('/v1/users/$uid/h2h/$opponentUid');
      return GNUserH2H.fromApi(json as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }
}

/// [EsportGroupStatsRepository] backed by the Game Note REST API.
class ApiEsportGroupStatsRepository implements EsportGroupStatsRepository {
  ApiEsportGroupStatsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  @override
  Future<GNEsportGroupStatsSummary?> getSummary(String groupId) async {
    final json = await _client.get('/v1/groups/$groupId/summary');
    return GNEsportGroupStatsSummary.fromApi(json as Map<String, dynamic>);
  }
}
