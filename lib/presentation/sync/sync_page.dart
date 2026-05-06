import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/sync/bloc/sync_bloc.dart';
import 'package:pes_arena/presentation/sync/views/step1_select_source.dart';
import 'package:pes_arena/presentation/sync/views/step2_map_players.dart';
import 'package:pes_arena/presentation/sync/views/step3_preview.dart';
import 'package:pes_arena/presentation/sync/views/step4_progress.dart';

class SyncPage extends StatelessWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SyncBloc>(
      create: (_) => getIt<SyncBloc>()..add(const SyncLoadInitialData()),
      child: const SyncView(),
    );
  }
}

class SyncView extends StatelessWidget {
  const SyncView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SyncBloc, SyncState>(
      listener: (context, state) {
        if (state.status == SyncStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đồng bộ thành công')),
          );
          Future.microtask(() {
            if (context.mounted) context.pop();
          });
        }
      },
      builder: (context, state) {
        final isRunning = state.status == SyncStatus.running;
        return Scaffold(
          appBar: AppBar(
            title: Text(_titleFor(state.step)),
            // Khi đang commit batch — ẩn back để user không thoát giữa chừng.
            // Step 4 view có PopScope chặn nốt swipe back.
            automaticallyImplyLeading: !isRunning,
            leading: isRunning
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => _onBack(context, state),
                  ),
          ),
          body: switch (state.step) {
            SyncStep.selectSource => const Step1SelectSource(),
            SyncStep.mapPlayers => const Step2MapPlayers(),
            SyncStep.preview => const Step3Preview(),
            SyncStep.executing => const Step4Progress(),
          },
        );
      },
    );
  }

  String _titleFor(SyncStep step) => switch (step) {
        SyncStep.selectSource => 'Chọn league & group',
        SyncStep.mapPlayers => 'Map người chơi',
        SyncStep.preview => 'Xác nhận',
        SyncStep.executing => 'Đang đồng bộ',
      };

  void _onBack(BuildContext context, SyncState state) {
    final bloc = context.read<SyncBloc>();
    switch (state.step) {
      case SyncStep.selectSource:
        context.pop();
      case SyncStep.mapPlayers:
        bloc.add(const SyncGoToStep(SyncStep.selectSource));
      case SyncStep.preview:
        bloc.add(const SyncGoToStep(SyncStep.mapPlayers));
      case SyncStep.executing:
        // No-op while running.
        if (state.status == SyncStatus.error) {
          bloc.add(const SyncGoToStep(SyncStep.preview));
        }
    }
  }
}
