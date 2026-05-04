import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/presentation/home/dashboard/models/dashboard_stats.dart';
import 'package:pes_arena/presentation/home/dashboard/widgets/stat_card_grid.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('hiển thị phần trăm và ngày vô địch gần nhất', (tester) async {
    await tester.pumpWidget(
      _wrap(
        StatCardGrid(
          stats: DashboardStats(
            tournamentsJoined: 12,
            finishedTournaments: 4,
            championCount: 1,
            runnerUpCount: 2,
            lastChampionAt: DateTime.now().subtract(const Duration(days: 3)),
            recentMatches: const [],
          ),
        ),
      ),
    );

    expect(find.text('12'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('3 ngày trước'), findsOneWidget);
  });

  testWidgets('hiển thị dấu gạch khi chưa có giải finished', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const StatCardGrid(
          stats: DashboardStats(
            tournamentsJoined: 0,
            finishedTournaments: 0,
            championCount: 0,
            runnerUpCount: 0,
            lastChampionAt: null,
            recentMatches: [],
          ),
        ),
      ),
    );

    expect(find.text('—'), findsNWidgets(3));
  });

  testWidgets('hiển thị hôm nay hoặc ngày cũ đúng format', (tester) async {
    await tester.pumpWidget(
      _wrap(
        StatCardGrid(
          stats: DashboardStats(
            tournamentsJoined: 1,
            finishedTournaments: 1,
            championCount: 1,
            runnerUpCount: 0,
            lastChampionAt: DateTime.now(),
            recentMatches: const [],
          ),
        ),
      ),
    );
    expect(find.text('Hôm nay'), findsOneWidget);

    await tester.pumpWidget(
      _wrap(
        StatCardGrid(
          stats: DashboardStats(
            tournamentsJoined: 1,
            finishedTournaments: 1,
            championCount: 1,
            runnerUpCount: 0,
            lastChampionAt: DateTime(2026, 1, 1),
            recentMatches: const [],
          ),
        ),
      ),
    );
    expect(find.text('01/01/2026'), findsOneWidget);
  });
}
