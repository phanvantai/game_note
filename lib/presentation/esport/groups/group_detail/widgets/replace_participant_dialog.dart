import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';
import 'package:pes_arena/presentation/users/user_item.dart';

import '../../../../../domain/repositories/esport/esport_league_repository.dart';

class ReplaceParticipantDialog extends StatefulWidget {
  final GNEsportLeague league;
  final List<GNUser> groupMembers;
  final EsportLeagueRepository leagueRepository;

  const ReplaceParticipantDialog({
    super.key,
    required this.league,
    required this.groupMembers,
    required this.leagueRepository,
  });

  @override
  State<ReplaceParticipantDialog> createState() =>
      _ReplaceParticipantDialogState();
}

class _ReplaceParticipantDialogState extends State<ReplaceParticipantDialog> {
  int _step = 0;
  GNEsportLeagueStat? _selectedOldStat;
  GNUser? _selectedNewUser;

  List<GNEsportLeagueStat> _stats = [];
  bool _loadingStats = true;

  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await widget.leagueRepository.getLeagueStats(widget.league.id);
      if (mounted) setState(() => _stats = stats);
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GroupDetailBloc, GroupDetailState>(
      listenWhen: (prev, curr) =>
          prev.replaceParticipantStatus != curr.replaceParticipantStatus,
      listener: (context, state) {
        if (state.replaceParticipantStatus == ViewStatus.success) {
          Navigator.of(context).pop();
          showToast('Đã thay thế thành công');
        } else if (state.replaceParticipantStatus == ViewStatus.failure) {
          showToast(state.replaceErrorMessage.isNotEmpty
              ? state.replaceErrorMessage
              : 'Có lỗi xảy ra, vui lòng thử lại');
        }
      },
      child: BlocBuilder<GroupDetailBloc, GroupDetailState>(
        buildWhen: (prev, curr) =>
            prev.replaceParticipantStatus != curr.replaceParticipantStatus,
        builder: (context, state) {
          final isSubmitting =
              state.replaceParticipantStatus == ViewStatus.loading;

          return AlertDialog(
            title: _buildTitle(),
            content: SizedBox(
              width: double.maxFinite,
              height: 320,
              child: isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : _buildStepContent(context),
            ),
            actions: _buildActions(context, state, isSubmitting),
          );
        },
      ),
    );
  }

  Widget _buildTitle() {
    final titles = [
      'Chọn người cần thay',
      'Chọn người thay thế',
      'Xác nhận thay thế',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titles[_step]),
        Text(
          widget.league.name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (_step) {
      case 0:
        return _buildSelectOldUser();
      case 1:
        return _buildSelectNewUser(context);
      case 2:
        return _buildConfirmStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSelectOldUser() {
    if (_loadingStats) {
      return const Center(child: CircularProgressIndicator());
    }
    final filtered = _stats
        .where((s) =>
            _searchText.isEmpty ||
            (s.user?.displayName ?? s.userId)
                .toLowerCase()
                .contains(_searchText.toLowerCase()))
        .toList();

    return Column(
      children: [
        TextField(
          decoration: appInputDecoration(
            context: context,
            hintText: 'Tìm theo tên',
            prefixIcon: Icons.search,
          ),
          onChanged: (v) => setState(() => _searchText = v),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'Không tìm thấy',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final stat = filtered[i];
                    final user = stat.user;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: user != null
                          ? _buildAvatar(user)
                          : const Icon(Icons.person),
                      title: Text(
                          user?.displayName ?? user?.email ?? stat.userId),
                      subtitle: user?.isPlaceholder == true
                          ? const Text('Placeholder')
                          : null,
                      trailing: user?.isPlaceholder == true
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Placeholder',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                              ),
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedOldStat = stat;
                          _step = 1;
                          _searchText = '';
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSelectNewUser(BuildContext context) {
    final filtered = widget.groupMembers
        .where((u) =>
            u.id != _selectedOldStat?.userId &&
            (_searchText.isEmpty ||
                (u.displayName ?? u.email ?? u.id)
                    .toLowerCase()
                    .contains(_searchText.toLowerCase())))
        .toList();

    return Column(
      children: [
        TextField(
          decoration: appInputDecoration(
            context: context,
            hintText: 'Tìm theo tên',
            prefixIcon: Icons.search,
          ),
          onChanged: (v) => setState(() => _searchText = v),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'Không tìm thấy',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final user = filtered[i];
                    return UserItem(
                      user: user,
                      onTap: () {
                        setState(() {
                          _selectedNewUser = user;
                          _step = 2;
                          _searchText = '';
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    final oldUser = _selectedOldStat?.user;
    final newUser = _selectedNewUser;
    final newAlreadyInLeague = widget.league.participants.contains(newUser?.id);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ConfirmRow(
            label: 'Thay',
            name: oldUser?.displayName ?? oldUser?.email ?? _selectedOldStat?.userId ?? '',
            photoUrl: oldUser?.photoUrl,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.arrow_downward,
                  color: Theme.of(context).colorScheme.primary, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          _ConfirmRow(
            label: 'Bằng',
            name: newUser?.displayName ?? newUser?.email ?? '',
            photoUrl: newUser?.photoUrl,
          ),
          if (newAlreadyInLeague) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .errorContainer
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Người này đã có trong giải. Thống kê của 2 người sẽ được cộng gộp lại.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Hành động này không thể hoàn tác.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    GroupDetailState state,
    bool isSubmitting,
  ) {
    if (isSubmitting) return [];

    return [
      TextButton(
        onPressed: () {
          if (_step == 0) {
            Navigator.of(context).pop();
          } else {
            setState(() {
              _step--;
              _searchText = '';
              if (_step == 0) _selectedOldStat = null;
              if (_step == 1) _selectedNewUser = null;
            });
          }
        },
        child: Text(_step == 0 ? 'Đóng' : 'Quay lại'),
      ),
      if (_step == 2)
        FilledButton(
          onPressed: _selectedOldStat != null && _selectedNewUser != null
              ? () => context.read<GroupDetailBloc>().add(
                    ReplaceLeagueParticipant(
                      leagueId: widget.league.id,
                      oldUserId: _selectedOldStat!.userId,
                      newUserId: _selectedNewUser!.id,
                    ),
                  )
              : null,
          child: const Text('Xác nhận'),
        ),
    ];
  }

  Widget _buildAvatar(GNUser user) {
    if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(user.photoUrl!),
      );
    }
    return CircleAvatar(
      radius: 18,
      child: Text(
        (user.displayName ?? user.email ?? '?').substring(0, 1).toUpperCase(),
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String name;
  final String? photoUrl;

  const _ConfirmRow({
    required this.label,
    required this.name,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ),
        const SizedBox(width: 8),
        if (photoUrl != null && photoUrl!.isNotEmpty)
          CircleAvatar(radius: 16, backgroundImage: NetworkImage(photoUrl!))
        else
          CircleAvatar(
            radius: 16,
            child: Text(
                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?'),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
