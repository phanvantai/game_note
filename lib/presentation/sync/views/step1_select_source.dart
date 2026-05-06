import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/presentation/sync/bloc/sync_bloc.dart';
import 'package:pes_arena/presentation/sync/widgets/step_nav_bar.dart';

class Step1SelectSource extends StatelessWidget {
  const Step1SelectSource({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        final body = _body(context, state);
        return Column(
          children: [
            Expanded(child: body),
            StepNavBar(
              previousLabel: 'Thoát',
              previousKey: const ValueKey('step1-prev'),
              nextKey: const ValueKey('step1-next'),
              nextLabel: 'Tiếp tục',
              onPrevious: () => context.pop(),
              onNext: state.canGoToMapping
                  ? () => context.read<SyncBloc>().add(
                      const SyncGoToStep(SyncStep.mapPlayers),
                    )
                  : null,
            ),
          ],
        );
      },
    );
  }

  Widget _body(BuildContext context, SyncState state) {
    if (state.status == SyncStatus.loading && state.offlineLeagues.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == SyncStatus.error && state.offlineLeagues.isEmpty) {
      return _ErrorView(message: state.errorMessage ?? '');
    }
    if (state.offlineLeagues.isEmpty) {
      return const Center(
        child: Text('Không có league offline nào để đồng bộ'),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader('League offline'),
        RadioGroup<int>(
          groupValue: state.selectedLeague?.id,
          onChanged: (v) {
            if (v != null) {
              context.read<SyncBloc>().add(SyncSelectOfflineLeague(v));
            }
          },
          child: Column(
            children: [
              for (final l in state.offlineLeagues)
                RadioListTile<int>(
                  key: ValueKey('offline-${l.id}'),
                  title: Text(l.name),
                  subtitle: Text(_describeLeague(l)),
                  value: l.id!,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _SectionHeader('Group online'),
        if (state.myGroups.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Bạn chưa tham gia group nào'),
          ),
        RadioGroup<String>(
          groupValue: state.selectedGroup?.id,
          onChanged: (v) {
            if (v != null) {
              context.read<SyncBloc>().add(SyncSelectGroup(v));
            }
          },
          child: Column(
            children: [
              for (final g in state.myGroups)
                RadioListTile<String>(
                  key: ValueKey('group-${g.id}'),
                  title: Text(g.groupName),
                  value: g.id,
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _describeLeague(dynamic league) {
    final players = league.players.length;
    return '$players người chơi · ${league.dateTime.toString().split(" ").first}';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
