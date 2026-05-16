import 'package:flutter/material.dart';
import 'package:pes_arena/core/widgets/user_display.dart';
import 'package:pes_arena/domain/repositories/esport/esport_group_repository.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/common/smart_back.dart';

enum _ResolutionType { transfer, deactivate }

class _Resolution {
  final _ResolutionType type;
  final String? newOwnerId;

  const _Resolution._(this.type, this.newOwnerId);
  const _Resolution.transfer(String userId)
    : this._(_ResolutionType.transfer, userId);
  const _Resolution.deactivate() : this._(_ResolutionType.deactivate, null);
}

class OwnershipResolutionPage extends StatefulWidget {
  final String currentUserId;
  final List<GNEsportGroup> groups;
  final List<GNEsportLeague> leagues;

  const OwnershipResolutionPage({
    super.key,
    required this.currentUserId,
    required this.groups,
    required this.leagues,
  });

  @override
  State<OwnershipResolutionPage> createState() =>
      _OwnershipResolutionPageState();
}

class _OwnershipResolutionPageState extends State<OwnershipResolutionPage> {
  final Map<String, _Resolution> _resolutions = {};
  Map<String, GNUser> _usersById = {};
  bool _loadingUsers = true;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    for (final group in widget.groups) {
      if (_candidateIds(group.members).isEmpty) {
        _resolutions[_groupKey(group.id)] = const _Resolution.deactivate();
      }
    }
    for (final league in widget.leagues) {
      if (_candidateIds(league.participants).isEmpty) {
        _resolutions[_leagueKey(league.id)] = const _Resolution.deactivate();
      }
    }
  }

  Future<void> _loadUsers() async {
    final ids = <String>{
      for (final group in widget.groups) ...group.members,
      for (final league in widget.leagues) ...league.participants,
    }.where((id) => id != widget.currentUserId).toList();
    final users = await getIt<GNFirestore>().getUsersById(ids);
    if (!mounted) return;
    setState(() {
      _usersById = users;
      _loadingUsers = false;
    });
  }

  List<String> _candidateIds(List<String> ids) {
    return ids.where((id) => id != widget.currentUserId).toList();
  }

  String _groupKey(String id) => 'group:$id';
  String _leagueKey(String id) => 'league:$id';

  bool get _canContinue {
    return !_applying &&
        widget.groups.every((g) => _resolutions.containsKey(_groupKey(g.id))) &&
        widget.leagues.every((l) => _resolutions.containsKey(_leagueKey(l.id)));
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      final groupRepo = getIt<EsportGroupRepository>();
      final leagueRepo = getIt<EsportLeagueRepository>();

      for (final group in widget.groups) {
        final resolution = _resolutions[_groupKey(group.id)];
        if (resolution == null) continue;
        if (resolution.type == _ResolutionType.transfer) {
          await groupRepo.transferGroupOwnership(
            groupId: group.id,
            newOwnerId: resolution.newOwnerId!,
          );
        } else {
          await groupRepo.deactivateGroup(group.id);
        }
      }

      for (final league in widget.leagues) {
        final resolution = _resolutions[_leagueKey(league.id)];
        if (resolution == null) continue;
        if (resolution.type == _ResolutionType.transfer) {
          await leagueRepo.transferLeagueOwnership(
            leagueId: league.id,
            newOwnerId: resolution.newOwnerId!,
          );
        } else {
          await leagueRepo.inactiveLeague(league);
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _applying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xử lý quyền sở hữu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const SmartBackButton(),
        title: const Text('Xử lý quyền sở hữu'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Text(
            'Bạn đang là chủ sở hữu của các nhóm/giải bên dưới. Hãy chuyển quyền cho thành viên khác hoặc ngừng hoạt động trước khi xoá tài khoản.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ...widget.groups.map(
            (group) => _OwnershipCard(
              icon: Icons.groups_outlined,
              title: group.groupName,
              subtitle: 'Nhóm',
              candidateIds: _candidateIds(group.members),
              usersById: _usersById,
              loadingUsers: _loadingUsers,
              value: _resolutions[_groupKey(group.id)],
              onChanged: (value) {
                setState(() => _resolutions[_groupKey(group.id)] = value);
              },
            ),
          ),
          ...widget.leagues.map(
            (league) => _OwnershipCard(
              icon: Icons.emoji_events_outlined,
              title: league.name,
              subtitle: 'Giải đấu',
              candidateIds: _candidateIds(league.participants),
              usersById: _usersById,
              loadingUsers: _loadingUsers,
              value: _resolutions[_leagueKey(league.id)],
              onChanged: (value) {
                setState(() => _resolutions[_leagueKey(league.id)] = value);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _canContinue ? _apply : null,
          child: _applying
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Tiếp tục xoá tài khoản'),
        ),
      ),
    );
  }
}

class _OwnershipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> candidateIds;
  final Map<String, GNUser> usersById;
  final bool loadingUsers;
  final _Resolution? value;
  final ValueChanged<_Resolution> onChanged;

  const _OwnershipCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.candidateIds,
    required this.usersById,
    required this.loadingUsers,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canTransfer = candidateIds.isNotEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<_ResolutionType>(
              showSelectedIcon: false,
              segments: [
                if (canTransfer)
                  const ButtonSegment(
                    value: _ResolutionType.transfer,
                    icon: Icon(Icons.swap_horiz),
                    label: Text('Chuyển'),
                  ),
                const ButtonSegment(
                  value: _ResolutionType.deactivate,
                  icon: Icon(Icons.block_outlined),
                  label: Text('Ngừng'),
                ),
              ],
              selected: value == null ? const {} : {value!.type},
              emptySelectionAllowed: true,
              onSelectionChanged: (selection) {
                final type = selection.firstOrNull;
                if (type == null) return;
                if (type == _ResolutionType.transfer) {
                  onChanged(_Resolution.transfer(candidateIds.first));
                } else {
                  onChanged(const _Resolution.deactivate());
                }
              },
            ),
            if (!canTransfer)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Không có thành viên khác để chuyển quyền.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (canTransfer && value?.type == _ResolutionType.transfer)
              DropdownButtonFormField<String>(
                initialValue: value?.newOwnerId ?? candidateIds.first,
                items: candidateIds
                    .map(
                      (id) => DropdownMenuItem(
                        value: id,
                        child: Text(
                          displayNameOrFallback(usersById[id], fallback: id),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: loadingUsers
                    ? null
                    : (id) {
                        if (id != null) onChanged(_Resolution.transfer(id));
                      },
              ),
          ],
        ),
      ),
    );
  }
}
