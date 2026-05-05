import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import '../../../../../widgets/gn_circle_avatar.dart';

/// Fixed-width card for leaderboard screenshot. No ScrollView — every column
/// is always fully visible when captured with RepaintBoundary.
class LeagueShareCard extends StatelessWidget {
  final String leagueName;
  final List<GNEsportLeagueStat> participants;
  final double cardWidth;
  final bool isDark;

  const LeagueShareCard({
    super.key,
    required this.leagueName,
    required this.participants,
    this.cardWidth = 520,
    this.isDark = true,
  });

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
  static const List<int> _flexes = [2, 7, 2, 2, 2, 2, 2, 2, 2, 3];

  static const _gold = Color(0xFFFBBF24);
  static const _silver = Color(0xFF9CA3AF);
  static const _bronze = Color(0xFFCD853F);

  // ── Dark palette ──────────────────────────────────────────────────────────
  static const _dkBg1 = Color(0xFF080818);
  static const _dkBg2 = Color(0xFF12122A);
  static const _dkBg3 = Color(0xFF0B1622);
  static const _dkTableHeaderBg = Color(0xFF1A2B3C);
  static const _dkTableHeaderText = Color(0xFF5B8DB8);
  static const _dkRowAlt = Color(0x0AFFFFFF);
  static const _dkNamePrimary = Colors.white;
  static const _dkNameSecondary = Color(0xFFCCCCCC);
  static const _dkStatText = Color(0xFFADB5BD);
  static const _dkPtsAccent = Color(0xFF38BDF8);
  static const _dkGdPos = Color(0xFF4ADE80);
  static const _dkGdNeg = Color(0xFFF87171);
  static const _dkRankText = Color(0xFF9CA3AF);
  static const _dkFooterText = Color(0xFF3D4F60);
  static const _dkFooterLine = Color(0xFF1E3347);

  // ── Light palette ─────────────────────────────────────────────────────────
  static const _ltBg1 = Color(0xFFF8F9FC);
  static const _ltBg2 = Color(0xFFFFFFFF);
  static const _ltTableHeaderBg = Color(0xFFF1F5F9);
  static const _ltTableHeaderText = Color(0xFF64748B);
  static const _ltRowAlt = Color(0xFFF8FAFC);
  static const _ltNamePrimary = Color(0xFF0F172A);
  static const _ltNameSecondary = Color(0xFF374151);
  static const _ltStatText = Color(0xFF6B7280);
  static const _ltPtsAccent = Color(0xFF7C3AED);
  static const _ltGdPos = Color(0xFF16A34A);
  static const _ltGdNeg = Color(0xFFDC2626);
  static const _ltRankText = Color(0xFF9CA3AF);
  static const _ltFooterText = Color(0xFFCBD5E1);
  static const _ltFooterLine = Color(0xFFE2E8F0);

  // ── Helpers ───────────────────────────────────────────────────────────────
  Color get _tableHeaderBg => isDark ? _dkTableHeaderBg : _ltTableHeaderBg;
  Color get _tableHeaderText => isDark ? _dkTableHeaderText : _ltTableHeaderText;
  Color get _rowAlt => isDark ? _dkRowAlt : _ltRowAlt;
  Color get _namePrimary => isDark ? _dkNamePrimary : _ltNamePrimary;
  Color get _nameSecondary => isDark ? _dkNameSecondary : _ltNameSecondary;
  Color get _statText => isDark ? _dkStatText : _ltStatText;
  Color get _ptsAccent => isDark ? _dkPtsAccent : _ltPtsAccent;
  Color get _gdPos => isDark ? _dkGdPos : _ltGdPos;
  Color get _gdNeg => isDark ? _dkGdNeg : _ltGdNeg;
  Color get _rankText => isDark ? _dkRankText : _ltRankText;
  Color get _footerText => isDark ? _dkFooterText : _ltFooterText;
  Color get _footerLine => isDark ? _dkFooterLine : _ltFooterLine;
  Color get _headerText => isDark ? Colors.white : _ltNamePrimary;

  Color _rankAccent(int index) =>
      index == 0 ? _gold : index == 1 ? _silver : _bronze;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [_dkBg1, _dkBg2, _dkBg3]
                : const [_ltBg1, _ltBg2, _ltBg2],
          ),
          borderRadius: BorderRadius.circular(20),
          border: isDark
              ? null
              : Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildTableHeader(),
            ...List.generate(
              participants.length,
              (i) => _buildRow(i, participants[i]),
            ),
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
            width: 26,
            height: 26,
            colorFilter: const ColorFilter.mode(_gold, BlendMode.srcIn),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              leagueName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _headerText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
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
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      decoration: BoxDecoration(
        color: _tableHeaderBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(_headers.length, (i) {
          final isName = _headers[i] == 'Cầu thủ';
          final isPts = _headers[i] == 'PTS';
          return Expanded(
            flex: _flexes[i],
            child: Text(
              _headers[i],
              textAlign: isName ? TextAlign.left : TextAlign.center,
              style: TextStyle(
                color: isPts ? _ptsAccent : _tableHeaderText,
                fontSize: isName ? 11 : 10,
                fontWeight: isPts ? FontWeight.w900 : FontWeight.w700,
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
    final accent = isTop3 ? _rankAccent(index) : null;
    final rowBg = isTop3
        ? accent!.withValues(alpha: isDark ? 0.06 : 0.05)
        : index % 2 != 0
            ? _rowAlt
            : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(8),
        border: isTop3
            ? Border(
                left: BorderSide(color: accent!, width: 3),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: _flexes[0],
            child: Center(child: _buildRankCell(index)),
          ),
          Expanded(
            flex: _flexes[1],
            child: Row(
              children: [
                GNCircleAvatar(size: 26, photoUrl: stats.user?.photoUrl),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    stats.user?.displayName ??
                        stats.user?.email ??
                        stats.user?.phoneNumber ??
                        '—',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isTop3 ? _namePrimary : _nameSecondary,
                      fontSize: 11,
                      fontWeight:
                          isTop3 ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (int ci = 2; ci < _headers.length; ci++)
            Expanded(
              flex: _flexes[ci],
              child: Center(
                child: _buildStatCell(_headers[ci], stats),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRankCell(int index) {
    final rank = index + 1;
    if (index < 3) {
      final accent = _rankAccent(index);
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(color: accent, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          '$rank',
          style: TextStyle(
            color: accent,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      );
    }
    return Text(
      '$rank',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: _rankText,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildStatCell(String header, GNEsportLeagueStat stats) {
    if (header == 'PTS') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _ptsAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${stats.points}',
          style: TextStyle(
            color: _ptsAccent,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    if (header == 'GD') {
      final gd = stats.goalDifference;
      final color = gd > 0 ? _gdPos : gd < 0 ? _gdNeg : _statText;
      return Text(
        gd > 0 ? '+$gd' : '$gd',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      );
    }

    return Text(
      _statValue(stats, header),
      style: TextStyle(
        color: _statText,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(height: 1, width: 40, color: _footerLine),
          const SizedBox(width: 8),
          Text(
            'PES Arena',
            style: TextStyle(
              color: _footerText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Container(height: 1, width: 40, color: _footerLine),
        ],
      ),
    );
  }

  String _statValue(GNEsportLeagueStat stats, String header) {
    return switch (header) {
      'P' => '${stats.matchesPlayed}',
      'W' => '${stats.wins}',
      'D' => '${stats.draws}',
      'L' => '${stats.losses}',
      'F' => '${stats.goals}',
      'A' => '${stats.goalsConceded}',
      'GD' => stats.goalDifference > 0
          ? '+${stats.goalDifference}'
          : '${stats.goalDifference}',
      'PTS' => '${stats.points}',
      _ => '—',
    };
  }
}
