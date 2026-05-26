import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/l10n/l10n.dart';
import 'package:pes_arena/presentation/sync/bloc/sync_bloc.dart';

/// Step cuối: commit batch lên Firestore. UI bị freeze trong lúc chạy
/// (PopScope chặn back, không có nút điều hướng) — phải đợi xong vì batch
/// atomic, không thể huỷ giữa chừng. Khi success, SyncView tự pop ra.
/// Khi error, hiện retry + back.
class Step4Progress extends StatelessWidget {
  const Step4Progress({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        final isRunning = state.status == SyncStatus.running;
        return PopScope(
          canPop: !isRunning,
          child: state.status == SyncStatus.error
              ? _ErrorView(state: state)
              : _RunningView(state: state),
        );
      },
    );
  }
}

class _RunningView extends StatelessWidget {
  const _RunningView({required this.state});
  final SyncState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Indeterminate trong lúc commit (Firestore batch atomic không
          // emit progress); chuyển sang determinate khi xong.
          LinearProgressIndicator(
            value: state.status == SyncStatus.success ? 1.0 : null,
          ),
          const SizedBox(height: 16),
          Text(
            state.progressLabel.isEmpty
                ? context.l10n.syncWritingData
                : state.progressLabel,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.syncDoNotClose,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.state});
  final SyncState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            state.errorMessage ?? context.l10n.commonErrorTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const ValueKey('retry'),
            onPressed: () => context.read<SyncBloc>().add(const SyncRun()),
            child: Text(context.l10n.syncRetry),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.read<SyncBloc>().add(
              const SyncGoToStep(SyncStep.preview),
            ),
            child: Text(context.l10n.syncBack),
          ),
        ],
      ),
    );
  }
}
