import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/presentation/home/widgets/ongoing_tournaments_banner.dart';
import 'package:pes_arena/presentation/home/ongoing_tournaments/bloc/ongoing_tournaments_bloc.dart';

class _MockOngoingBloc
    extends MockBloc<OngoingTournamentsEvent, OngoingTournamentsState>
    implements OngoingTournamentsBloc {}

GNEsportLeague _league({required String id, String? status}) => GNEsportLeague(
  id: id,
  ownerId: 'u1',
  groupId: 'g1',
  name: 'L $id',
  startDate: DateTime(2026, 5, 1),
  endDate: DateTime(2026, 5, 10),
  isActive: true,
  description: '',
  participants: const [],
  rankPayoutEnabled: false,
  rankPayouts: const [],
  defaultMatchCost: 0,
  status: status,
);

Widget _wrap(OngoingTournamentsBloc ongoingBloc) {
  return BlocProvider<OngoingTournamentsBloc>.value(
    value: ongoingBloc,
    child: MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: OngoingTournamentsBanner()),
          ),
          GoRoute(
            path: '/tournament/:leagueId',
            builder: (context, state) => Scaffold(
              body: Center(
                child: Text('detail ${state.pathParameters['leagueId']}'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  test('giữ giải đấu có status = ongoing', () {
    final result = filterOngoingLeagues([
      _league(id: 'a', status: 'ongoing'),
      _league(id: 'b', status: 'ongoing'),
    ]);
    expect(result.map((l) => l.id), ['a', 'b']);
  });

  test('loại giải đấu có status = finished dù endDate còn trong tương lai', () {
    final result = filterOngoingLeagues([
      _league(id: 'done', status: 'finished'),
    ]);
    expect(result, isEmpty);
  });

  test('loại giải đấu có status = upcoming', () {
    final result = filterOngoingLeagues([
      _league(id: 'soon', status: 'upcoming'),
    ]);
    expect(result, isEmpty);
  });

  test('status null/legacy → coi như upcoming, không hiện trên banner', () {
    final result = filterOngoingLeagues([_league(id: 'legacy', status: null)]);
    expect(result, isEmpty);
  });

  test('lọc đúng tập con khi mix status', () {
    final result = filterOngoingLeagues([
      _league(id: 'a', status: 'ongoing'),
      _league(id: 'b', status: 'finished'),
      _league(id: 'c', status: 'upcoming'),
      _league(id: 'd', status: 'ongoing'),
    ]);
    expect(result.map((l) => l.id), ['a', 'd']);
  });

  testWidgets('banner rebuild đúng khi danh sách league thay đổi', (
    tester,
  ) async {
    final bloc = _MockOngoingBloc();
    final sharedLeagues = [_league(id: 'a', status: 'ongoing')];
    final initialState = OngoingTournamentsState(leagues: sharedLeagues);
    final sameRefState = OngoingTournamentsState(leagues: sharedLeagues);
    final changedState = OngoingTournamentsState(
      leagues: [
        ...sharedLeagues,
        _league(id: 'b', status: 'ongoing'),
      ],
    );
    final controller = StreamController<OngoingTournamentsState>();

    when(() => bloc.state).thenReturn(initialState);
    whenListen(bloc, controller.stream, initialState: initialState);

    await tester.pumpWidget(_wrap(bloc));
    expect(find.text('L a'), findsOneWidget);
    expect(find.text('L b'), findsNothing);

    controller.add(sameRefState);
    await tester.pumpAndSettle();
    expect(find.text('L a'), findsOneWidget);
    expect(find.text('L b'), findsNothing);

    controller.add(changedState);
    await tester.pumpAndSettle();
    expect(find.text('L b'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('L a'), findsOneWidget);

    await controller.close();
  });

  testWidgets('tap giải đấu trong banner dẫn tới tournament detail', (
    tester,
  ) async {
    final bloc = _MockOngoingBloc();
    final state = OngoingTournamentsState(
      leagues: [_league(id: 't1', status: 'ongoing')],
    );

    when(() => bloc.state).thenReturn(state);
    whenListen(
      bloc,
      Stream<OngoingTournamentsState>.empty(),
      initialState: state,
    );

    await tester.pumpWidget(_wrap(bloc));
    await tester.tap(find.text('L t1'));
    await tester.pumpAndSettle();

    expect(find.text('detail t1'), findsOneWidget);
  });
}
