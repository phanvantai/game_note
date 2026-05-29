import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../firebase/firestore/esport/league/gn_esport_league.dart';

class TournamentItem extends StatelessWidget {
  final GNEsportLeague league;
  final Function() onTap;
  const TournamentItem({super.key, required this.league, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = GNEsportLeagueStatusExtension.fromString(league.status);
    final title = league.name.isEmpty
        ? '${league.group?.groupName ?? ''} - ${DateFormat('dd/MM/yyyy').format(league.startDate)}'
        : league.name;
    final groupName = league.group?.groupName ?? 'Chưa rõ nhóm';
    final description = league.description;
    final dateRange = league.endDate == null
        ? DateFormat('dd/MM/yyyy').format(league.startDate)
        : '${DateFormat('dd/MM').format(league.startDate)} - ${DateFormat('dd/MM/yyyy').format(league.endDate!)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgPicture.asset(
                  'assets/svg/trophy-solid.svg',
                  colorFilter: ColorFilter.mode(status.color, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(status: status),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoMetaItem(
                          icon: Icons.groups_2_outlined,
                          label: groupName,
                        ),
                        _InfoMetaItem(
                          icon: Icons.people_alt_outlined,
                          label: '${league.participants.length} người',
                        ),
                        _InfoMetaItem(
                          icon: Icons.calendar_today_outlined,
                          label: dateRange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final GNEsportLeagueStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Text(
      status.name,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: status.color,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _InfoMetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoMetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
