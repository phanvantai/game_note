import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/widgets/league_share_card.dart';

GNUser _user(String id, String name) {
  return GNUser(
    id: id,
    displayName: name,
    phoneNumber: null,
    email: '$id@example.com',
    photoUrl: null,
    role: 'user',
    fcmToken: '',
  );
}

GNEsportLeagueStat _stat({
  required String userId,
  required String name,
  required int wins,
}) {
  return GNEsportLeagueStat(
    id: 'stat_$userId',
    userId: userId,
    leagueId: 'league_1',
    matchesPlayed: 3,
    goals: wins * 3,
    goalsConceded: 1,
    wins: wins,
    draws: 0,
    losses: 3 - wins,
    user: _user(userId, name),
  );
}

GNEsportMatch _match({
  required String id,
  required String homeId,
  required String awayId,
  required int homeScore,
  required int awayScore,
  int matchCost = 0,
  int? knockoutRound,
  GNUser? homeTeam,
  GNUser? awayTeam,
}) {
  return GNEsportMatch(
    id: id,
    homeTeamId: homeId,
    awayTeamId: awayId,
    homeScore: homeScore,
    awayScore: awayScore,
    date: DateTime(2026),
    isFinished: true,
    leagueId: 'league_1',
    matchCost: matchCost,
    knockoutRound: knockoutRound,
    phase: knockoutRound != null ? 'knockout' : null,
    homeTeam: homeTeam,
    awayTeam: awayTeam,
  );
}

GNEsportLeagueStat _statWithUser({
  required String userId,
  required String name,
  required int wins,
  int matchesPlayed = 3,
  int goals = 1,
  int goalsConceded = 1,
  int draws = 0,
  int losses = 0,
  GNUser? user,
}) {
  final fallbackUser =
      user ??
      GNUser(
        id: userId,
        displayName: name,
        phoneNumber: null,
        email: '$userId@example.com',
        photoUrl: null,
        role: 'user',
        fcmToken: '',
      );

  return GNEsportLeagueStat(
    id: 'stat_$userId',
    userId: userId,
    leagueId: 'league_1',
    matchesPlayed: matchesPlayed,
    goals: goals,
    goalsConceded: goalsConceded,
    wins: wins,
    draws: draws,
    losses: losses,
    user: fallbackUser,
  );
}

Future<void> _pumpShareCard(
  WidgetTester tester, {
  required bool includeRankCost,
  bool isDark = false,
  bool isBracketMode = false,
  List<int> rankPayouts = const [50000, 100000],
  List<GNEsportLeagueStat>? participants,
  List<GNEsportMatch> matches = const [],
  List<GNEsportMatch> knockoutMatches = const [],
}) async {
  final defaultParticipants = [
    _stat(userId: 'u1', name: 'Người chơi A', wins: 3),
    _stat(userId: 'u2', name: 'Người chơi B', wins: 2),
    _stat(userId: 'u3', name: 'Người chơi C', wins: 1),
  ];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LeagueShareCard(
            leagueName: 'Test League',
            participants: participants ?? defaultParticipants,
            includeRankCost: includeRankCost,
            rankPayouts: rankPayouts,
            matches: matches,
            knockoutMatches: knockoutMatches,
            isDark: isDark,
            isBracketMode: isBracketMode,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders full cost section in light mode', (tester) async {
    await _pumpShareCard(
      tester,
      includeRankCost: true,
      matches: [
        _match(
          id: 'match_1',
          homeId: 'u1',
          awayId: 'u2',
          homeScore: 3,
          awayScore: 1,
          matchCost: 20000,
        ),
      ],
    );

    expect(find.text('Chi phí'), findsOneWidget);
    expect(find.text('Theo thứ hạng'), findsOneWidget);
    expect(find.text('Theo trận'), findsOneWidget);
    expect(find.text('Tổng ròng'), findsOneWidget);
    expect(find.text('20k'), findsOneWidget);
    expect(find.text('50k'), findsOneWidget);
    expect(find.text('100k'), findsOneWidget);
  });

  testWidgets('renders full cost section in dark mode', (tester) async {
    await _pumpShareCard(
      tester,
      includeRankCost: true,
      isDark: true,
      matches: [
        _match(
          id: 'match_1',
          homeId: 'u1',
          awayId: 'u2',
          homeScore: 3,
          awayScore: 1,
          matchCost: 20000,
        ),
      ],
    );

    expect(find.text('Chi phí'), findsOneWidget);
    expect(find.text('Theo thứ hạng'), findsOneWidget);
    expect(find.text('Theo trận'), findsOneWidget);
    expect(find.text('Tổng ròng'), findsOneWidget);
    final leagueTitle = tester.widget<Text>(find.text('Test League'));
    expect(leagueTitle.style?.color, Colors.white);
    expect(find.text('20k'), findsOneWidget);
    expect(find.text('50k'), findsOneWidget);
    expect(find.text('100k'), findsOneWidget);
  });

  testWidgets('hides rank cost section when disabled', (tester) async {
    await _pumpShareCard(tester, includeRankCost: false);

    expect(find.text('Chi phí'), findsNothing);
    expect(find.text('Theo trận'), findsNothing);
    expect(find.text('Tổng ròng'), findsNothing);
    expect(find.text('50k'), findsNothing);
    expect(find.text('100k'), findsNothing);
  });

  testWidgets('render section Theo bracket khi isBracketMode=true', (
    tester,
  ) async {
    await _pumpShareCard(
      tester,
      includeRankCost: true,
      isBracketMode: true,
      rankPayouts: const [100000, 50000],
      matches: const [],
      participants: [
        _stat(userId: 'u1', name: 'Đội trưởng', wins: 4),
        _stat(userId: 'u2', name: 'Người về nhì', wins: 3),
        _stat(userId: 'u3', name: 'Bán kết 1', wins: 2),
        _stat(userId: 'u4', name: 'Bán kết 2', wins: 1),
      ],
      knockoutMatches: [
        _match(
          id: 'semi_1',
          homeId: 'u1',
          awayId: 'u3',
          homeScore: 2,
          awayScore: 0,
          knockoutRound: 0,
        ),
        _match(
          id: 'semi_2',
          homeId: 'u2',
          awayId: 'u4',
          homeScore: 3,
          awayScore: 1,
          knockoutRound: 0,
        ),
        _match(
          id: 'final',
          homeId: 'u1',
          awayId: 'u2',
          homeScore: 2,
          awayScore: 1,
          knockoutRound: 1,
        ),
      ],
    );

    expect(find.text('Chi phí'), findsOneWidget);
    expect(find.text('Theo bracket'), findsOneWidget);
    expect(find.text('Theo thứ hạng'), findsNothing);
    expect(find.text('Theo trận'), findsNothing);
    expect(find.text('Tổng ròng'), findsOneWidget);
    expect(find.text('100k'), findsOneWidget);
    expect(find.text('50k'), findsNWidgets(2));
  });

  testWidgets('hiển thị chỉ khoản theo trận khi không có rank payout', (
    tester,
  ) async {
    await _pumpShareCard(
      tester,
      includeRankCost: true,
      rankPayouts: const [],
      matches: [
        _match(
          id: 'match_1',
          homeId: 'u1',
          awayId: 'u2',
          homeScore: 3,
          awayScore: 1,
          matchCost: 20000,
        ),
        _match(
          id: 'match_2',
          homeId: 'u1',
          awayId: 'u3',
          homeScore: 2,
          awayScore: 0,
          matchCost: 15000,
        ),
      ],
      participants: [
        _stat(userId: 'u1', name: 'Người chơi A', wins: 3),
        _stat(userId: 'u2', name: 'Người chơi B', wins: 2),
        _stat(userId: 'u3', name: 'Người chơi C', wins: 1),
      ],
    );

    expect(find.text('Chi phí'), findsOneWidget);
    expect(find.text('Theo thứ hạng'), findsNothing);
    expect(find.text('Theo bracket'), findsNothing);
    expect(find.text('Theo trận'), findsOneWidget);
    expect(find.text('20k'), findsOneWidget);
    expect(find.text('15k'), findsOneWidget);
    expect(find.text('Tổng ròng'), findsOneWidget);
    expect(find.text('+35k'), findsOneWidget);
  });

  testWidgets('dùng email khi displayName null', (tester) async {
    await _pumpShareCard(
      tester,
      includeRankCost: false,
      participants: [
        GNEsportLeagueStat(
          id: 'stat_email',
          userId: 'u_email',
          leagueId: 'league_1',
          matchesPlayed: 1,
          goals: 2,
          goalsConceded: 1,
          wins: 1,
          draws: 0,
          losses: 0,
          user: GNUser(
            id: 'u_email',
            displayName: null,
            phoneNumber: null,
            email: 'email-only@example.com',
            photoUrl: null,
            role: 'user',
            fcmToken: '',
          ),
        ),
        _statWithUser(
          userId: 'u2',
          name: 'Người chơi B',
          wins: 1,
          matchesPlayed: 1,
          goals: 1,
          goalsConceded: 1,
        ),
        _statWithUser(
          userId: 'u3',
          name: 'Người chơi C',
          wins: 1,
          matchesPlayed: 1,
          goals: 1,
          goalsConceded: 1,
        ),
      ],
    );

    expect(find.text('email-only@example.com'), findsOneWidget);
  });

  testWidgets('dùng số điện thoại khi displayName và email null', (
    tester,
  ) async {
    await _pumpShareCard(
      tester,
      includeRankCost: false,
      participants: [
        GNEsportLeagueStat(
          id: 'stat_phone',
          userId: 'u_phone',
          leagueId: 'league_1',
          matchesPlayed: 1,
          goals: 2,
          goalsConceded: 1,
          wins: 1,
          draws: 0,
          losses: 0,
          user: GNUser(
            id: 'u_phone',
            displayName: null,
            phoneNumber: '0900111222',
            email: null,
            photoUrl: null,
            role: 'user',
            fcmToken: '',
          ),
        ),
        _statWithUser(
          userId: 'u2',
          name: 'Người chơi B',
          wins: 1,
          matchesPlayed: 1,
          goals: 1,
          goalsConceded: 1,
        ),
        _statWithUser(
          userId: 'u3',
          name: 'Người chơi C',
          wins: 1,
          matchesPlayed: 1,
          goals: 1,
          goalsConceded: 1,
        ),
      ],
    );

    expect(find.text('0900111222'), findsOneWidget);
  });

  testWidgets('hiển thị chênh lệch bại trận khi âm', (tester) async {
    await _pumpShareCard(
      tester,
      includeRankCost: false,
      participants: [
        _statWithUser(
          userId: 'u_neg',
          name: 'Người chơi A',
          wins: 0,
          draws: 0,
          losses: 2,
          matchesPlayed: 2,
          goals: 1,
          goalsConceded: 4,
        ),
        _statWithUser(
          userId: 'u2',
          name: 'Người chơi B',
          wins: 2,
          draws: 0,
          losses: 0,
          matchesPlayed: 2,
          goals: 4,
          goalsConceded: 1,
        ),
        _statWithUser(
          userId: 'u3',
          name: 'Người chơi C',
          wins: 1,
          draws: 1,
          losses: 0,
          matchesPlayed: 2,
          goals: 3,
          goalsConceded: 3,
        ),
      ],
    );

    expect(find.text('-3'), findsOneWidget);
  });

  testWidgets('hiển thị nút bấm rút gọn khi nhiều khoản theo hạng', (
    tester,
  ) async {
    await _pumpShareCard(
      tester,
      includeRankCost: true,
      isDark: false,
      rankPayouts: [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000],
      participants: List.generate(
        10,
        (index) => _statWithUser(
          userId: 'u$index',
          name: 'Player $index',
          wins: 10 - index,
          matchesPlayed: 1,
          goals: 5 + index,
          goalsConceded: index,
          losses: 0,
        ),
      ),
      matches: const [],
    );

    expect(find.text('+3 khoản khác'), findsAtLeastNWidgets(1));
    expect(find.text('Theo thứ hạng'), findsOneWidget);
  });

  testWidgets(
    'sử dụng team từ match khi user của stat thiếu để hiển thị chi phí',
    (tester) async {
      final homeTeam = _user('u10', 'Nhà');
      final awayTeam = _user('u11', 'Khách');

      await _pumpShareCard(
        tester,
        includeRankCost: true,
        matches: [
          _match(
            id: 'match_1',
            homeId: 'u10',
            awayId: 'u11',
            homeScore: 5,
            awayScore: 2,
            matchCost: 20000,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
          ),
        ],
        participants: [
          GNEsportLeagueStat(
            id: 'stat_u10',
            userId: 'u10',
            leagueId: 'league_1',
            matchesPlayed: 1,
            goals: 3,
            goalsConceded: 2,
            wins: 1,
            draws: 0,
            losses: 0,
            user: null,
          ),
          GNEsportLeagueStat(
            id: 'stat_u11',
            userId: 'u11',
            leagueId: 'league_1',
            matchesPlayed: 1,
            goals: 2,
            goalsConceded: 3,
            wins: 0,
            draws: 0,
            losses: 1,
            user: null,
          ),
        ],
      );

      expect(find.text('Nhà'), findsAtLeastNWidgets(1));
      expect(find.text('Khách'), findsAtLeastNWidgets(1));
    },
  );
}
