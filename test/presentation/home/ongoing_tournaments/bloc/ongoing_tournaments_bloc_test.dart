import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/presentation/home/ongoing_tournaments/bloc/ongoing_tournaments_bloc.dart';

class _MockRepo extends Mock implements EsportLeagueRepository {}

class _FakeLeague extends Fake implements GNEsportLeague {}

GNEsportLeague _league(String id) => GNEsportLeague(
      id: id,
      ownerId: 'owner',
      groupId: 'G1',
      name: 'League $id',
      startDate: DateTime(2026, 1, 1),
      isActive: true,
      description: '',
      participants: const [],
    );

void main() {
  setUpAll(() => registerFallbackValue(_FakeLeague()));

  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  group('OngoingTournamentsBloc — LoadOngoingTournaments', () {
    blocTest<OngoingTournamentsBloc, OngoingTournamentsState>(
      'groupIds rỗng → emit success với leagues rỗng ngay lập tức (không gọi repo)',
      build: () => OngoingTournamentsBloc(repo),
      act: (bloc) => bloc.add(const LoadOngoingTournaments([])),
      expect: () => [
        isA<OngoingTournamentsState>()
            .having((s) => s.status, 'status', ViewStatus.success)
            .having((s) => s.leagues, 'leagues', isEmpty)
            .having((s) => s.loadedGroupIds, 'loadedGroupIds', isEmpty),
      ],
      verify: (_) =>
          verifyNever(() => repo.getActiveLeaguesByGroupIds(any())),
    );

    blocTest<OngoingTournamentsBloc, OngoingTournamentsState>(
      'groupIds có giá trị → emit loading rồi success với leagues trả về',
      build: () {
        when(() => repo.getActiveLeaguesByGroupIds(any()))
            .thenAnswer((_) async => [_league('L1'), _league('L2')]);
        return OngoingTournamentsBloc(repo);
      },
      act: (bloc) =>
          bloc.add(const LoadOngoingTournaments(['G1', 'G2'])),
      expect: () => [
        isA<OngoingTournamentsState>()
            .having((s) => s.status, 'status', ViewStatus.loading),
        isA<OngoingTournamentsState>()
            .having((s) => s.status, 'status', ViewStatus.success)
            .having(
              (s) => s.leagues.map((l) => l.id).toList(),
              'league ids',
              ['L1', 'L2'],
            )
            .having(
              (s) => s.loadedGroupIds,
              'loadedGroupIds',
              ['G1', 'G2'],
            ),
      ],
    );

    blocTest<OngoingTournamentsBloc, OngoingTournamentsState>(
      'repo throw → emit loading rồi failure với errorMessage',
      build: () {
        when(() => repo.getActiveLeaguesByGroupIds(any()))
            .thenThrow(Exception('network error'));
        return OngoingTournamentsBloc(repo);
      },
      act: (bloc) =>
          bloc.add(const LoadOngoingTournaments(['G1'])),
      expect: () => [
        isA<OngoingTournamentsState>()
            .having((s) => s.status, 'status', ViewStatus.loading),
        isA<OngoingTournamentsState>()
            .having((s) => s.status, 'status', ViewStatus.failure)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              isNotEmpty,
            ),
      ],
    );
  });
}
