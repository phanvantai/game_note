import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  blocTest<TournamentBloc, TournamentState>(
    'RefreshTournaments tăng refreshTick dù dữ liệu trả về không đổi',
    build: () {
      final myLeagues = [_league()];
      final otherPage = LeaguesPage(
        items: [_league(id: 'L2')],
        lastDoc: null,
        hasMore: false,
      );

      when(() => repo.getMyLeagues()).thenAnswer((_) async => myLeagues);
      when(
        () => repo.getOtherLeagues(startAfter: null, limit: 20),
      ).thenAnswer((_) async => otherPage);

      return TournamentBloc(repo);
    },
    act: (bloc) => bloc.add(RefreshTournaments()),
    skip: 4,
    expect: () => [
      isA<TournamentState>()
          .having((s) => s.refreshTick, 'refreshTick', 1)
          .having((s) => s.myLeagues.length, 'myLeagues', 1)
          .having((s) => s.otherLeagues.length, 'otherLeagues', 1),
    ],
  );
}
