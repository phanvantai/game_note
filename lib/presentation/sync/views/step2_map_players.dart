import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/data/sync/mapping_target.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/offline/domain/entities/player_model.dart';
import 'package:pes_arena/presentation/sync/bloc/sync_bloc.dart';
import 'package:pes_arena/presentation/sync/widgets/step_nav_bar.dart';

class Step2MapPlayers extends StatelessWidget {
  const Step2MapPlayers({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        final league = state.selectedLeague;
        if (league == null) {
          return const Center(child: Text('Chưa chọn league'));
        }
        final players = league.players.map((p) => p.playerModel).toList();
        final dupUid = _findDuplicateUid(state);
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: players.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, i) {
                  final p = players[i];
                  return _PlayerRow(
                    player: p,
                    members: state.groupMembers,
                    target: state.mappings[p.id],
                  );
                },
              ),
            ),
            if (dupUid != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Lỗi: 2 người chơi cùng map vào 1 user',
                  key: const ValueKey('dup-warning'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            StepNavBar(
              previousKey: const ValueKey('step2-prev'),
              nextKey: const ValueKey('step2-next'),
              nextLabel: 'Xem trước',
              onPrevious: () => context
                  .read<SyncBloc>()
                  .add(const SyncGoToStep(SyncStep.selectSource)),
              onNext: state.canGoToPreview
                  ? () => context
                      .read<SyncBloc>()
                      .add(const SyncGoToStep(SyncStep.preview))
                  : null,
            ),
          ],
        );
      },
    );
  }

  String? _findDuplicateUid(SyncState state) {
    final seen = <String>{};
    for (final t in state.mappings.values) {
      if (t is MapToExisting) {
        if (!seen.add(t.uid)) return t.uid;
      }
    }
    return null;
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.members,
    required this.target,
  });
  final PlayerModel player;
  final List<GNUser> members;
  final MappingTarget? target;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('player-${player.id}'),
      title: Text(player.fullname),
      subtitle: Text(_describeTarget(target, members)),
      trailing: TextButton(
        key: ValueKey('map-btn-${player.id}'),
        onPressed: () => _openPicker(context),
        child: const Text('Chọn'),
      ),
    );
  }

  String _describeTarget(MappingTarget? t, List<GNUser> members) {
    return switch (t) {
      null => 'Chưa map',
      MapToExisting(uid: final uid) =>
        '→ ${members.firstWhere(
              (m) => m.id == uid,
              orElse: () => GNUser(
                id: uid,
                displayName: uid,
                phoneNumber: null,
                email: null,
                photoUrl: null,
                role: 'user',
                fcmToken: '',
              ),
            ).displayName ?? uid}',
      CreatePlaceholder(displayName: final n) => '→ $n (mới)',
    };
  }

  Future<void> _openPicker(BuildContext context) async {
    final bloc = context.read<SyncBloc>();
    final result = await showModalBottomSheet<MappingTarget>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Map "${player.fullname}"',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (members.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Group chưa có thành viên nào'),
                  ),
                for (final m in members)
                  ListTile(
                    key: ValueKey('pick-${m.id}'),
                    title: Text(m.displayName ?? m.id),
                    leading: const Icon(Icons.person_outline),
                    onTap: () =>
                        Navigator.of(sheetContext).pop(MapToExisting(m.id)),
                  ),
                const Divider(),
                ListTile(
                  key: const ValueKey('pick-create-placeholder'),
                  leading: const Icon(Icons.person_add_alt_1),
                  title: const Text('Tạo user mới (placeholder)'),
                  onTap: () async {
                    final name = await _promptName(sheetContext, player.fullname);
                    if (name != null && name.isNotEmpty && sheetContext.mounted) {
                      Navigator.of(sheetContext).pop(CreatePlaceholder(name));
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result != null) {
      bloc.add(SyncSetMapping(playerId: player.id!, target: result));
    }
  }

  Future<String?> _promptName(BuildContext context, String initial) async {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tên người chơi mới'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Tên hiển thị'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              key: const ValueKey('placeholder-confirm'),
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Tạo'),
            ),
          ],
        );
      },
    );
  }
}
