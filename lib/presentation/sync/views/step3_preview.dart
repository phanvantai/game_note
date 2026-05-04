import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/data/sync/migration_plan.dart';
import 'package:pes_arena/offline/domain/entities/league_model.dart';
import 'package:pes_arena/offline/domain/entities/match_model.dart';
import 'package:pes_arena/presentation/sync/bloc/sync_bloc.dart';
import 'package:pes_arena/presentation/sync/widgets/step_nav_bar.dart';

class Step3Preview extends StatelessWidget {
  const Step3Preview({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        final league = state.selectedLeague;
        final group = state.selectedGroup;
        final plan = state.plan;
        if (league == null || group == null || plan == null) {
          return const Center(child: Text('Thiếu dữ liệu'));
        }
        final uidToName = _buildUidToNameMap(state);

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              _LeagueHeader(
                name: league.name,
                date: league.dateTime,
                groupName: group.groupName,
                totalOps: plan.totalOps,
              ),
              const TabBar(
                tabs: [
                  Tab(
                    key: ValueKey('tab-offline'),
                    text: 'Offline (gốc)',
                  ),
                  Tab(
                    key: ValueKey('tab-online'),
                    text: 'Online (sẽ tạo)',
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _OfflineTab(league: league),
                    _OnlineTab(plan: plan, uidToName: uidToName),
                  ],
                ),
              ),
              StepNavBar(
                previousKey: const ValueKey('step3-prev'),
                nextKey: const ValueKey('confirm-sync'),
                nextLabel: 'Đồng bộ',
                onPrevious: () => context
                    .read<SyncBloc>()
                    .add(const SyncGoToStep(SyncStep.mapPlayers)),
                onNext: () => context.read<SyncBloc>().add(const SyncRun()),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, String> _buildUidToNameMap(SyncState state) {
    final map = <String, String>{};
    for (final m in state.groupMembers) {
      map[m.id] = m.displayName ?? m.id;
    }
    if (state.plan != null) {
      for (final p in state.plan!.placeholderUsers) {
        map[p.id] = '${p.displayName} (mới)';
      }
    }
    return map;
  }
}

// ---------------- Header ----------------

class _LeagueHeader extends StatelessWidget {
  const _LeagueHeader({
    required this.name,
    required this.date,
    required this.groupName,
    required this.totalOps,
  });
  final String name;
  final DateTime date;
  final String groupName;
  final int totalOps;

  @override
  Widget build(BuildContext context) {
    final dateText = date.toString().split(' ').first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Ngày: $dateText'),
              Text('Group đích: $groupName'),
              Text(
                'Sẽ ghi $totalOps bản ghi lên server',
                key: const ValueKey('ops-count'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Tabs ----------------

class _OfflineTab extends StatelessWidget {
  const _OfflineTab({required this.league});
  final LeagueModel league;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final p in league.players)
        _StandingRow(
          uid: '${p.playerModel.id}',
          name: p.playerModel.fullname,
          matchesPlayed: p.totalPlayed,
          wins: p.wins,
          draws: p.draws,
          losses: p.losses,
          // Offline lưu goalDifferent — split GF/GA không có sẵn nên tự derive
          // từ matches để fair compare với online.
          goals: _goalsFor(league, p.playerModel.id),
          goalsConceded: _goalsAgainst(league, p.playerModel.id),
        ),
    ];
    final matches = [
      for (final r in league.rounds)
        for (final m in r.matches)
          if (_isFinished(m))
            _MatchPair(
              id: '${m.id}',
              homeName: m.home!.playerModel.fullname,
              awayName: m.away!.playerModel.fullname,
              homeScore: m.home!.score!,
              awayScore: m.away!.score!,
            ),
    ];
    return _PreviewBody(
      key: const ValueKey('offline-body'),
      rows: rows,
      matches: matches,
    );
  }

  bool _isFinished(MatchModel m) =>
      m.status &&
      m.home != null &&
      m.away != null &&
      m.home!.score != null &&
      m.away!.score != null;

  int _goalsFor(LeagueModel league, int? playerId) {
    if (playerId == null) return 0;
    var sum = 0;
    for (final r in league.rounds) {
      for (final m in r.matches) {
        if (!_isFinished(m)) continue;
        if (m.home!.playerModel.id == playerId) sum += m.home!.score!;
        if (m.away!.playerModel.id == playerId) sum += m.away!.score!;
      }
    }
    return sum;
  }

  int _goalsAgainst(LeagueModel league, int? playerId) {
    if (playerId == null) return 0;
    var sum = 0;
    for (final r in league.rounds) {
      for (final m in r.matches) {
        if (!_isFinished(m)) continue;
        if (m.home!.playerModel.id == playerId) sum += m.away!.score!;
        if (m.away!.playerModel.id == playerId) sum += m.home!.score!;
      }
    }
    return sum;
  }
}

class _OnlineTab extends StatelessWidget {
  const _OnlineTab({required this.plan, required this.uidToName});
  final MigrationPlan plan;
  final Map<String, String> uidToName;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final s in plan.statDocs)
        _StandingRow(
          uid: s.userId,
          name: uidToName[s.userId] ?? s.userId,
          matchesPlayed: s.matchesPlayed,
          wins: s.wins,
          draws: s.draws,
          losses: s.losses,
          goals: s.goals,
          goalsConceded: s.goalsConceded,
        ),
    ];
    final matches = [
      for (final m in plan.matches)
        _MatchPair(
          id: m.id,
          homeName: uidToName[m.homeTeamId] ?? m.homeTeamId,
          awayName: uidToName[m.awayTeamId] ?? m.awayTeamId,
          homeScore: m.homeScore!,
          awayScore: m.awayScore!,
        ),
    ];
    return _PreviewBody(
      key: const ValueKey('online-body'),
      rows: rows,
      matches: matches,
      footer: plan.placeholderUsers.isEmpty
          ? null
          : _PlaceholdersFooter(placeholders: plan.placeholderUsers),
    );
  }
}

// ---------------- Shared body ----------------

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    super.key,
    required this.rows,
    required this.matches,
    this.footer,
  });
  final List<_StandingRow> rows;
  final List<_MatchPair> matches;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Bảng xếp hạng',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _StandingsTable(rows: rows),
        const SizedBox(height: 24),
        Text(
          'Kết quả trận đấu (${matches.length})',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (matches.isEmpty)
          const Text('Không có trận nào đã đấu')
        else
          _MatchesList(matches: matches),
        if (footer != null) ...[
          const SizedBox(height: 24),
          footer!,
        ],
      ],
    );
  }
}

// ---------------- Standings table ----------------

class _StandingRow {
  const _StandingRow({
    required this.uid,
    required this.name,
    required this.matchesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goals,
    required this.goalsConceded,
  });
  final String uid;
  final String name;
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int goals;
  final int goalsConceded;

  int get points => wins * 3 + draws;
  int get gd => goals - goalsConceded;
}

class _StandingsTable extends StatelessWidget {
  const _StandingsTable({required this.rows});
  final List<_StandingRow> rows;

  @override
  Widget build(BuildContext context) {
    final sorted = [...rows]..sort((a, b) {
        final p = b.points.compareTo(a.points);
        if (p != 0) return p;
        final g = b.gd.compareTo(a.gd);
        if (g != 0) return g;
        final gf = b.goals.compareTo(a.goals);
        if (gf != 0) return gf;
        return a.name.compareTo(b.name);
      });
    return Card(
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowHeight: 36,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 36,
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Người chơi')),
            DataColumn(label: Text('MP'), numeric: true),
            DataColumn(label: Text('W'), numeric: true),
            DataColumn(label: Text('D'), numeric: true),
            DataColumn(label: Text('L'), numeric: true),
            DataColumn(label: Text('GF'), numeric: true),
            DataColumn(label: Text('GA'), numeric: true),
            DataColumn(label: Text('GD'), numeric: true),
            DataColumn(label: Text('Pts'), numeric: true),
          ],
          rows: [
            for (var i = 0; i < sorted.length; i++)
              DataRow(
                key: ValueKey('standings-${sorted[i].uid}'),
                cells: [
                  DataCell(Text('${i + 1}')),
                  DataCell(Text(sorted[i].name)),
                  DataCell(Text('${sorted[i].matchesPlayed}')),
                  DataCell(Text('${sorted[i].wins}')),
                  DataCell(Text('${sorted[i].draws}')),
                  DataCell(Text('${sorted[i].losses}')),
                  DataCell(Text('${sorted[i].goals}')),
                  DataCell(Text('${sorted[i].goalsConceded}')),
                  DataCell(Text(_signed(sorted[i].gd))),
                  DataCell(Text(
                    '${sorted[i].points}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  )),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _signed(int v) => v > 0 ? '+$v' : '$v';
}

// ---------------- Matches ----------------

class _MatchPair {
  const _MatchPair({
    required this.id,
    required this.homeName,
    required this.awayName,
    required this.homeScore,
    required this.awayScore,
  });
  final String id;
  final String homeName;
  final String awayName;
  final int homeScore;
  final int awayScore;
}

class _MatchesList extends StatelessWidget {
  const _MatchesList({required this.matches});
  final List<_MatchPair> matches;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < matches.length; i++) ...[
            if (i > 0)
              Divider(
                height: 0,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
            Padding(
              key: ValueKey('match-${matches[i].id}'),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child:
                        Text(matches[i].homeName, textAlign: TextAlign.right),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${matches[i].homeScore}  -  ${matches[i].awayScore}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(child: Text(matches[i].awayName)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlaceholdersFooter extends StatelessWidget {
  const _PlaceholdersFooter({required this.placeholders});
  final List<PlannedPlaceholder> placeholders;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Người chơi mới sẽ được tạo (${placeholders.length})',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        for (final p in placeholders)
          Padding(
            key: ValueKey('placeholder-${p.id}'),
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.person_add_alt_1, size: 16),
                const SizedBox(width: 8),
                Text(p.displayName),
              ],
            ),
          ),
      ],
    );
  }
}
