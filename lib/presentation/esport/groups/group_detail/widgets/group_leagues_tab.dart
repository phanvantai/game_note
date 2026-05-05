import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';
import 'package:pes_arena/routing.dart';

import 'replace_participant_dialog.dart';

class GroupLeaguesTab extends StatelessWidget {
  const GroupLeaguesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupDetailBloc, GroupDetailState>(
      buildWhen: (prev, curr) =>
          prev.leaguesStatus != curr.leaguesStatus ||
          prev.leagues != curr.leagues ||
          prev.isOwner != curr.isOwner,
      builder: (context, state) {
        if (state.leaguesStatus == ViewStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.leagues.isEmpty) {
          return Center(
            child: Text(
              'Chưa có giải đấu nào',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.leagues.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final league = state.leagues[index];
            return _LeagueManageCard(
              league: league,
              isOwner: state.isOwner,
              members: state.members,
            );
          },
        );
      },
    );
  }
}

class _LeagueManageCard extends StatelessWidget {
  final GNEsportLeague league;
  final bool isOwner;
  final List<GNUser> members;

  const _LeagueManageCard({
    required this.league,
    required this.isOwner,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = GNEsportLeagueStatusExtension.fromString(league.status);

    return InkWell(
      onTap: () => context.push(Routing.tournamentDetailPath(league.id)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.48),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    league.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StatusChip(status: status),
                      const SizedBox(width: 8),
                      if (!league.isActive) ...[
                        _InactiveChip(),
                        const SizedBox(width: 8),
                      ],
                      Icon(
                        Icons.people_alt_outlined,
                        size: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${league.participants.length} người',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      if (league.mergeCompleted) ...[
                        const SizedBox(width: 8),
                        _MergeCompletedBadge(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isOwner)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: league.mergeCompleted
                        ? 'Đánh dấu chưa xử lý'
                        : 'Đánh dấu đã xử lý merge',
                    icon: Icon(
                      league.mergeCompleted
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: league.mergeCompleted
                          ? Colors.green
                          : colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    onPressed: () => context.read<GroupDetailBloc>().add(
                      SetLeagueMergeCompleted(
                        leagueId: league.id,
                        completed: !league.mergeCompleted,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Quản lý người chơi',
                    icon: Icon(
                      Icons.manage_accounts_outlined,
                      color: colorScheme.primary,
                    ),
                    onPressed: () => _openReplaceDialog(context),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _openReplaceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<GroupDetailBloc>(),
        child: ReplaceParticipantDialog(
          league: league,
          groupMembers: members,
          leagueRepository: getIt<EsportLeagueRepository>(),
        ),
      ),
    );
  }
}

class _InactiveChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        'Đã xoá',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MergeCompletedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 10, color: Colors.green),
          const SizedBox(width: 3),
          Text(
            'Đã xử lý',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final GNEsportLeagueStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.name,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: status.color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
