import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/widgets/gn_circle_avatar.dart';
import 'package:pes_arena/presentation/home/dashboard/detail/h2h_detail_page.dart';
import 'package:pes_arena/presentation/home/dashboard/models/opponent_stat.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

OpponentStat _opponent({
  String id = 'U1',
  String name = 'Player A',
  int wins = 5,
  int draws = 2,
  int losses = 3,
  String? opponentPhotoUrl,
}) {
  return OpponentStat(
    opponentId: id,
    opponentDisplayName: name,
    opponentPhotoUrl: opponentPhotoUrl,
    matchesPlayed: wins + draws + losses,
    wins: wins,
    draws: draws,
    losses: losses,
  );
}

List<String> _opponentNameOrder(
  WidgetTester tester,
  Set<String> expectedNames,
) {
  return tester
      .widgetList<Text>(
        find.byWidgetPredicate(
          (widget) => widget is Text && expectedNames.contains(widget.data),
        ),
      )
      .map((text) => text.data!)
      .toList();
}

void main() {
  group('H2HDetailPage — danh sách rỗng', () {
    testWidgets('hiển thị icon khi không có đối thủ', (tester) async {
      await tester.pumpWidget(_wrap(const H2HDetailPage(opponents: [])));

      expect(find.byIcon(Icons.groups_2_outlined), findsOneWidget);
    });
  });

  group('H2HDetailPage — danh sách có đối thủ', () {
    testWidgets('hiển thị tên đối thủ', (tester) async {
      await tester.pumpWidget(
        _wrap(
          H2HDetailPage(
            opponents: [
              _opponent(name: 'Player A'),
              _opponent(
                id: 'U2',
                name: 'Player B',
                wins: 1,
                draws: 0,
                losses: 9,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Player A'), findsOneWidget);
      expect(find.text('Player B'), findsOneWidget);
    });

    testWidgets('mặc định sắp xếp theo số trận nhiều nhất lên đầu', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          H2HDetailPage(
            opponents: [
              _opponent(id: 'U1', name: 'Few', wins: 1, draws: 0, losses: 0),
              _opponent(id: 'U2', name: 'Many', wins: 5, draws: 3, losses: 4),
            ],
          ),
        ),
      );

      final items = tester
          .widgetList<Text>(
            find.byWidgetPredicate(
              (w) => w is Text && (w.data == 'Many' || w.data == 'Few'),
            ),
          )
          .toList();

      // Many (12 matches) should appear before Few (1 match)
      expect(items.first.data, 'Many');
    });

    testWidgets('có thể chuyển sang sort theo tỉ lệ thắng', (tester) async {
      await tester.pumpWidget(
        _wrap(
          H2HDetailPage(
            opponents: [
              _opponent(id: 'U1', name: 'Alice', wins: 1, draws: 0, losses: 9),
              _opponent(id: 'U2', name: 'Bob', wins: 8, draws: 1, losses: 1),
              _opponent(id: 'U3', name: 'Cara', wins: 5, draws: 2, losses: 1),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Thắng nhiều'));
      await tester.pumpAndSettle();

      final items = _opponentNameOrder(tester, {'Alice', 'Bob', 'Cara'});
      expect(items.first, 'Bob');
    });

    testWidgets('có thể chuyển sang sort theo tỉ lệ thua', (tester) async {
      await tester.pumpWidget(
        _wrap(
          H2HDetailPage(
            opponents: [
              _opponent(id: 'U1', name: 'Alice', wins: 1, draws: 0, losses: 9),
              _opponent(id: 'U2', name: 'Bob', wins: 8, draws: 1, losses: 1),
              _opponent(id: 'U3', name: 'Cara', wins: 0, draws: 0, losses: 1),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Thua nhiều'));
      await tester.pumpAndSettle();

      final items = _opponentNameOrder(tester, {'Alice', 'Bob', 'Cara'});
      expect(items.first, 'Cara');
    });

    testWidgets('hiển thị avatar ảnh khi có link ảnh đối thủ', (tester) async {
      await tester.pumpWidget(
        _wrap(
          H2HDetailPage(
            opponents: [
              _opponent(
                id: 'U1',
                name: 'Avatar Guy',
                wins: 1,
                draws: 1,
                losses: 0,
                opponentPhotoUrl: 'https://example.com/avatar.png',
              ),
            ],
          ),
        ),
      );

      expect(find.byType(GNCircleAvatar), findsOneWidget);
    });

    testWidgets('hiển thị trạng thái không tỉ lệ W/D/L khi chưa có trận', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          H2HDetailPage(
            opponents: [
              const OpponentStat(
                opponentId: 'U1',
                opponentDisplayName: 'No games',
                opponentPhotoUrl: null,
                matchesPlayed: 0,
                wins: 0,
                draws: 0,
                losses: 0,
              ),
            ],
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsNothing);
    });
  });

  group('H2HDetailPage — AppBar', () {
    testWidgets('hiển thị title đúng', (tester) async {
      await tester.pumpWidget(_wrap(H2HDetailPage(opponents: [_opponent()])));

      expect(find.text('Lịch sử đối đầu'), findsOneWidget);
    });
  });
}
