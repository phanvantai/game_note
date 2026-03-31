import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import '../../../../../widgets/gn_circle_avatar.dart';

/// A self-contained, fixed-width card widget used for rendering the full
/// leaderboard screenshot. It does NOT use any ScrollView, so every column
/// is always fully visible when captured with RepaintBoundary.
class LeagueShareCard extends StatelessWidget {
  final String leagueName;
  final List<GNEsportLeagueStat> participants;
  final double cardWidth;

  const LeagueShareCard({
    Key? key,
    required this.leagueName,
    required this.participants,
    this.cardWidth = 480,
  }) : super(key: key);

  // Column header labels & flex values
  static const List<String> _headers = [
    '#',
    'Cầu thủ',
    'P',
    'W',
    'D',
    'L',
    'F',
    'A',
    'GD',
    'PTS',
  ];

  // Flex weights for each column
  static const List<int> _flexes = [2, 7, 2, 2, 2, 2, 2, 2, 2, 3];

  @override
  Widget build(BuildContext context) {
    // Use a fixed dark theme so the screenshot always looks consistent.
    return Material(
      color: Colors.transparent,
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F1E), Color(0xFF1A1A35), Color(0xFF0D1B2A)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildTableHeader(),
            ...List.generate(participants.length, (i) {
              return _buildRow(i, participants[i]);
            }),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/svg/trophy-solid.svg',
            width: 28,
            height: 28,
            colorFilter: const ColorFilter.mode(
              Color(0xFFFFD700),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              leagueName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(_headers.length, (i) {
          final isName = _headers[i] == 'Cầu thủ';
          return Expanded(
            flex: _flexes[i],
            child: Text(
              _headers[i],
              textAlign: isName ? TextAlign.left : TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF6CB4E4),
                fontSize: isName ? 11 : 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRow(int index, GNEsportLeagueStat stats) {
    final isTop3 = index < 3;
    final rankColors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFB0C4DE), // Silver
      const Color(0xFFCD7F32), // Bronze
    ];
    final rowColor =
        index % 2 == 0 ? const Color(0x00000000) : const Color(0x0AFFFFFF);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: isTop3 ? rankColors[index].withValues(alpha: 0.05) : rowColor,
        borderRadius: BorderRadius.circular(8),
        border: isTop3
            ? Border.all(
                color: rankColors[index].withValues(alpha: 0.25),
                width: 0.5,
              )
            : null,
      ),
      child: Row(
        children: [
          // Rank
          Expanded(
            flex: _flexes[0],
            child: Center(
              child: isTop3
                  ? _buildRankBadge(index + 1, rankColors[index])
                  : Text(
                      '${index + 1}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFCCCCCC),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          // Player name + avatar
          Expanded(
            flex: _flexes[1],
            child: Row(
              children: [
                GNCircleAvatar(
                  size: 26,
                  photoUrl: stats.user?.photoUrl,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    stats.user?.displayName ??
                        stats.user?.email ??
                        stats.user?.phoneNumber ??
                        '—',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isTop3 ? Colors.white : const Color(0xFFDDDDDD),
                      fontSize: 11,
                      fontWeight: isTop3 ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Stats columns
          for (int ci = 2; ci < _headers.length; ci++)
            Expanded(
              flex: _flexes[ci],
              child: Text(
                _statValue(stats, _headers[ci]),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _headers[ci] == 'PTS'
                      ? const Color(0xFF6CB4E4)
                      : const Color(0xFFCCCCCC),
                  fontSize: _headers[ci] == 'PTS' ? 12 : 11,
                  fontWeight:
                      _headers[ci] == 'PTS' ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank, Color color) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 1,
            width: 40,
            color: const Color(0xFF334455),
          ),
          const SizedBox(width: 8),
          const Text(
            'PES Arena',
            style: TextStyle(
              color: Color(0xFF445566),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 1,
            width: 40,
            color: const Color(0xFF334455),
          ),
        ],
      ),
    );
  }

  String _statValue(GNEsportLeagueStat stats, String header) {
    switch (header) {
      case 'P':
        return '${stats.matchesPlayed}';
      case 'W':
        return '${stats.wins}';
      case 'D':
        return '${stats.draws}';
      case 'L':
        return '${stats.losses}';
      case 'F':
        return '${stats.goals}';
      case 'A':
        return '${stats.goalsConceded}';
      case 'GD':
        final gd = stats.goalDifference;
        return gd > 0 ? '+$gd' : '$gd';
      case 'PTS':
        return '${stats.points}';
      default:
        return '—';
    }
  }
}
