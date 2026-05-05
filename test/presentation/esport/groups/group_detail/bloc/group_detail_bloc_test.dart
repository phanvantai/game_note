import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart'; // ignore: unused_import
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/domain/repositories/esport/esport_group_repository.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';

class _MockGroupRepo extends Mock implements EsportGroupRepository {}

class _MockLeagueRepo extends Mock implements EsportLeagueRepository {}

GNEsportGroup _group({String ownerId = 'owner1'}) => GNEsportGroup(
      id: 'G1',
      groupName: 'Test Group',
      ownerId: ownerId,
      members: const ['owner1'],
      description: '',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      status: 'active',
    );

GNEsportLeague _league(String id) => GNEsportLeague(
      id: id,
      ownerId: 'owner1',
      groupId: 'G1',
      name: 'League $id',
      startDate: DateTime(2026, 1, 1),
      isActive: true,
      description: '',
      participants: const [],
    );

void main() {
  late _MockGroupRepo groupRepo;
  late _MockLeagueRepo leagueRepo;

  setUp(() {
    groupRepo = _MockGroupRepo();
    leagueRepo = _MockLeagueRepo();
    setShowToastImpl((msg, {gravity = ToastGravity.BOTTOM}) {});
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  GroupDetailBloc _bloc() =>
      GroupDetailBloc(groupRepo, leagueRepo, _group(), currentUserId: 'owner1');

  group('LoadGroupLeagues', () {
    blocTest<GroupDetailBloc, GroupDetailState>(
      'phát ra leaguesStatus loading → success khi load thành công',
      build: _bloc,
      setUp: () {
        when(() => leagueRepo.getLeaguesByGroupId('G1'))
            .thenAnswer((_) async => [_league('L1'), _league('L2')]);
      },
      act: (bloc) => bloc.add(const LoadGroupLeagues('G1')),
      expect: () => [
        isA<GroupDetailState>()
            .having((s) => s.leaguesStatus, 'leaguesStatus', ViewStatus.loading),
        isA<GroupDetailState>()
            .having((s) => s.leaguesStatus, 'leaguesStatus', ViewStatus.success)
            .having((s) => s.leagues.length, 'leagues.length', 2),
      ],
    );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'phát ra leaguesStatus failure khi repo ném lỗi',
      build: _bloc,
      setUp: () {
        when(() => leagueRepo.getLeaguesByGroupId('G1'))
            .thenThrow(Exception('network error'));
      },
      act: (bloc) => bloc.add(const LoadGroupLeagues('G1')),
      expect: () => [
        isA<GroupDetailState>()
            .having((s) => s.leaguesStatus, 'leaguesStatus', ViewStatus.loading),
        isA<GroupDetailState>()
            .having((s) => s.leaguesStatus, 'leaguesStatus', ViewStatus.failure),
      ],
    );
  });

  group('SetLeagueMergeCompleted', () {
    blocTest<GroupDetailBloc, GroupDetailState>(
      'cập nhật mergeCompleted = true trong local state',
      build: _bloc,
      seed: () => GroupDetailState(group: _group(), leagues: [_league('L1')]),
      setUp: () {
        when(() => leagueRepo.setMergeCompleted('L1', completed: true))
            .thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const SetLeagueMergeCompleted(
        leagueId: 'L1',
        completed: true,
      )),
      expect: () => [
        isA<GroupDetailState>().having(
          (s) => s.leagues.first.mergeCompleted,
          'mergeCompleted',
          true,
        ),
      ],
    );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'toggle mergeCompleted = false',
      build: _bloc,
      seed: () => GroupDetailState(
        group: _group(),
        leagues: [_league('L1').copyWith(mergeCompleted: true)],
      ),
      setUp: () {
        when(() => leagueRepo.setMergeCompleted('L1', completed: false))
            .thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const SetLeagueMergeCompleted(
        leagueId: 'L1',
        completed: false,
      )),
      expect: () => [
        isA<GroupDetailState>().having(
          (s) => s.leagues.first.mergeCompleted,
          'mergeCompleted',
          false,
        ),
      ],
    );
  });

  group('ReplaceLeagueParticipant', () {
    blocTest<GroupDetailBloc, GroupDetailState>(
      'phát ra replaceParticipantStatus loading → success và tự load lại leagues',
      build: _bloc,
      setUp: () {
        when(() => leagueRepo.replaceParticipant(
              leagueId: 'L1',
              oldUserId: 'old',
              newUserId: 'new',
            )).thenAnswer((_) async {});
        when(() => leagueRepo.getLeaguesByGroupId('G1'))
            .thenAnswer((_) async => [_league('L1')]);
      },
      act: (bloc) => bloc.add(const ReplaceLeagueParticipant(
        leagueId: 'L1',
        oldUserId: 'old',
        newUserId: 'new',
      )),
      expect: () => [
        isA<GroupDetailState>().having(
            (s) => s.replaceParticipantStatus,
            'status',
            ViewStatus.loading),
        isA<GroupDetailState>().having(
            (s) => s.replaceParticipantStatus,
            'status',
            ViewStatus.success),
        // LoadGroupLeagues triggered after success
        isA<GroupDetailState>()
            .having((s) => s.leaguesStatus, 'leaguesStatus', ViewStatus.loading),
        isA<GroupDetailState>()
            .having((s) => s.leaguesStatus, 'leaguesStatus', ViewStatus.success),
      ],
    );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'phát ra replaceParticipantStatus failure khi repo ném lỗi',
      build: _bloc,
      setUp: () {
        when(() => leagueRepo.replaceParticipant(
              leagueId: 'L1',
              oldUserId: 'old',
              newUserId: 'new',
            )).thenThrow(Exception('replace failed'));
      },
      act: (bloc) => bloc.add(const ReplaceLeagueParticipant(
        leagueId: 'L1',
        oldUserId: 'old',
        newUserId: 'new',
      )),
      expect: () => [
        isA<GroupDetailState>().having(
            (s) => s.replaceParticipantStatus,
            'status',
            ViewStatus.loading),
        isA<GroupDetailState>()
            .having((s) => s.replaceParticipantStatus, 'status',
                ViewStatus.failure)
            .having((s) => s.replaceErrorMessage, 'replaceErrorMessage',
                contains('replace failed')),
      ],
    );
  });
}
