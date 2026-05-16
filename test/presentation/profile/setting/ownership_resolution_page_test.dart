import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/domain/repositories/esport/esport_group_repository.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/profile/setting/ownership_resolution_page.dart';

class _MockGroupRepo extends Mock implements EsportGroupRepository {}

class _MockLeagueRepo extends Mock implements EsportLeagueRepository {}

void main() {
  late _MockGroupRepo groupRepo;
  late _MockLeagueRepo leagueRepo;

  setUpAll(() {
    registerFallbackValue(_league());
  });

  setUp(() {
    groupRepo = _MockGroupRepo();
    leagueRepo = _MockLeagueRepo();
    getIt.registerSingleton<GNFirestore>(GNFirestore(FakeFirebaseFirestore()));
    getIt.registerFactory<EsportGroupRepository>(() => groupRepo);
    getIt.registerFactory<EsportLeagueRepository>(() => leagueRepo);
  });

  tearDown(() => getIt.reset());

  Widget page({List<GNEsportGroup>? groups, List<GNEsportLeague>? leagues}) {
    return MaterialApp(
      home: OwnershipResolutionPage(
        currentUserId: 'owner',
        groups: groups ?? const [],
        leagues: leagues ?? const [],
      ),
    );
  }

  testWidgets('renders items and disables continue until all are resolved', (
    tester,
  ) async {
    await tester.pumpWidget(
      page(
        groups: [
          _group(members: ['owner', 'u1']),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nhóm test'), findsOneWidget);
    expect(find.text('Tiếp tục xoá tài khoản'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('group without another member cannot transfer', (tester) async {
    await tester.pumpWidget(
      page(
        groups: [
          _group(members: ['owner']),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Không có thành viên khác để chuyển quyền.'),
      findsOneWidget,
    );
    expect(find.text('Chuyển'), findsNothing);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('apply calls deactivate methods for deactivate choices', (
    tester,
  ) async {
    final group = _group(members: ['owner']);
    final league = _league(participants: ['owner']);
    when(() => groupRepo.deactivateGroup(group.id)).thenAnswer((_) async {});
    when(() => leagueRepo.inactiveLeague(league)).thenAnswer((_) async {});

    await tester.pumpWidget(page(groups: [group], leagues: [league]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục xoá tài khoản'));
    await tester.pumpAndSettle();

    verify(() => groupRepo.deactivateGroup(group.id)).called(1);
    verify(() => leagueRepo.inactiveLeague(league)).called(1);
  });

  testWidgets('apply calls transfer group ownership when transfer selected', (
    tester,
  ) async {
    final group = _group(members: ['owner', 'u1']);
    when(
      () =>
          groupRepo.transferGroupOwnership(groupId: group.id, newOwnerId: 'u1'),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(page(groups: [group]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chuyển'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục xoá tài khoản'));
    await tester.pumpAndSettle();

    verify(
      () =>
          groupRepo.transferGroupOwnership(groupId: group.id, newOwnerId: 'u1'),
    ).called(1);
  });

  testWidgets('apply calls transfer league ownership when transfer selected', (
    tester,
  ) async {
    final league = _league(participants: ['owner', 'u1']);
    when(
      () => leagueRepo.transferLeagueOwnership(
        leagueId: league.id,
        newOwnerId: 'u1',
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(page(leagues: [league]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chuyển'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục xoá tài khoản'));
    await tester.pumpAndSettle();

    verify(
      () => leagueRepo.transferLeagueOwnership(
        leagueId: league.id,
        newOwnerId: 'u1',
      ),
    ).called(1);
  });

  testWidgets('transfer dropdown can select a different member', (
    tester,
  ) async {
    final group = _group(members: ['owner', 'u1', 'u2']);
    when(
      () =>
          groupRepo.transferGroupOwnership(groupId: group.id, newOwnerId: 'u2'),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(page(groups: [group]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chuyển'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('u2').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục xoá tài khoản'));
    await tester.pumpAndSettle();

    verify(
      () =>
          groupRepo.transferGroupOwnership(groupId: group.id, newOwnerId: 'u2'),
    ).called(1);
  });

  testWidgets('can switch transfer selection back to deactivate', (
    tester,
  ) async {
    final group = _group(members: ['owner', 'u1']);
    when(() => groupRepo.deactivateGroup(group.id)).thenAnswer((_) async {});

    await tester.pumpWidget(page(groups: [group]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chuyển'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ngừng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục xoá tài khoản'));
    await tester.pumpAndSettle();

    verify(() => groupRepo.deactivateGroup(group.id)).called(1);
  });

  testWidgets('apply failure shows error and keeps page open', (tester) async {
    final group = _group(members: ['owner']);
    when(() => groupRepo.deactivateGroup(group.id)).thenThrow(Exception('x'));

    await tester.pumpWidget(page(groups: [group]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục xoá tài khoản'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Không thể xử lý quyền sở hữu'), findsOneWidget);
    expect(find.text('Xử lý quyền sở hữu'), findsOneWidget);
  });
}

GNEsportGroup _group({List<String> members = const ['owner', 'u1']}) {
  final now = DateTime(2026, 5, 10);
  return GNEsportGroup(
    id: 'G1',
    groupName: 'Nhóm test',
    ownerId: 'owner',
    members: members,
    description: '',
    createdAt: now,
    updatedAt: now,
    status: 'active',
  );
}

GNEsportLeague _league({List<String> participants = const ['owner', 'u1']}) {
  return GNEsportLeague(
    id: 'L1',
    ownerId: 'owner',
    groupId: 'G1',
    name: 'Giải test',
    startDate: DateTime(2026, 5, 10),
    isActive: true,
    description: '',
    participants: participants,
  );
}
