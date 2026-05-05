import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/presentation/esport/tournament/bloc/tournament_bloc.dart';

class _MockRepo extends Mock implements EsportLeagueRepository {}

GNEsportLeague _league({String id = 'L1'}) {
  return GNEsportLeague(
    id: id,
    ownerId: 'owner',
    groupId: 'G1',
    name: 'League $id',
    startDate: DateTime(2026, 1, 1),
    isActive: true,
    description: '',
    participants: const ['owner'],
  );
}

LeaguesPage _page(List<GNEsportLeague> items, {bool hasMore = false}) =>
    LeaguesPage(items: items, lastDoc: null, hasMore: hasMore);

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    // Default stubs for the 3 initial loads fired by the constructor.
    when(
      () => repo.getMyLeagues(startAfter: any(named: 'startAfter'), limit: any(named: 'limit')),
    ).thenAnswer((_) async => _page([_league()]));
    when(
      () => repo.getManagedLeagues(startAfter: any(named: 'startAfter'), limit: any(named: 'limit')),
    ).thenAnswer((_) async => _page([]));
    when(
      () => repo.getOtherLeagues(startAfter: any(named: 'startAfter'), limit: any(named: 'limit')),
    ).thenAnswer((_) async => _page([_league(id: 'L2')]));
  });

  // Constructor fires LoadMyLeagues + LoadManagedLeagues + LoadOtherLeagues,
  // each emitting loading then success = 6 states before the test act.
  blocTest<TournamentBloc, TournamentState>(
    'RefreshTournaments tăng refreshTick dù dữ liệu trả về không đổi',
    build: () => TournamentBloc(repo),
    act: (bloc) => bloc.add(RefreshTournaments()),
    skip: 6,
    expect: () => [
      isA<TournamentState>()
          .having((s) => s.refreshTick, 'refreshTick', 1)
          .having((s) => s.myLeagues.length, 'myLeagues', 1)
          .having((s) => s.otherLeagues.length, 'otherLeagues', 1),
    ],
  );

  blocTest<TournamentBloc, TournamentState>(
    'LoadMoreMyLeagues appends next page',
    build: () {
      // First call: hasMore=true so load-more is allowed.
      var callCount = 0;
      when(
        () => repo.getMyLeagues(
          startAfter: any(named: 'startAfter'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        return _page([_league(id: 'L${callCount}')], hasMore: callCount == 1);
      });
      return TournamentBloc(repo);
    },
    act: (bloc) async {
      await Future.delayed(Duration.zero);
      bloc.add(LoadMoreMyLeagues());
    },
    skip: 6,
    expect: () => [
      isA<TournamentState>().having(
        (s) => s.myStatus,
        'loading',
        ViewStatus.loading,
      ),
      isA<TournamentState>().having(
        (s) => s.myLeagues.length,
        'myLeagues appended',
        2,
      ),
    ],
  );

  blocTest<TournamentBloc, TournamentState>(
    'LoadMoreManagedLeagues não dispara quando managedHasMore=false',
    build: () {
      when(
        () => repo.getManagedLeagues(
          startAfter: any(named: 'startAfter'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => _page([], hasMore: false));
      return TournamentBloc(repo);
    },
    act: (bloc) async {
      await Future.delayed(Duration.zero);
      bloc.add(LoadMoreManagedLeagues());
    },
    skip: 6,
    expect: () => [],
  );
}
