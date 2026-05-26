import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/l10n/l10n.dart';
import 'package:pes_arena/offline/presentation/components/select_player_view.dart';
import 'package:share_plus/share_plus.dart';

import 'bloc/league_detail_bloc.dart';
import 'components/matches_view.dart';
import 'components/table_view.dart';
import 'league_detail_floating_button.dart';

class LeagueDetailView extends StatefulWidget {
  const LeagueDetailView({super.key});

  @override
  State<LeagueDetailView> createState() => _LeagueDetailViewState();
}

class _LeagueDetailViewState extends State<LeagueDetailView> {
  final GlobalKey _tableKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeagueDetailBloc, LeagueDetailState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(state.model?.name ?? ''),
            actions: _buildActions(context, state),
          ),
          body: SafeArea(bottom: false, child: _leagueDetail(context, state)),
          floatingActionButton: state.status.needFloatButton
              ? const LeagueDetailFloatingButton()
              : null,
        );
      },
    );
  }

  List<Widget> _buildActions(BuildContext context, LeagueDetailState state) {
    if (state.status.isAddingPlayer && state.enableConfirmSelectPlayers) {
      return [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'confirm') {
              BlocProvider.of<LeagueDetailBloc>(
                context,
              ).add(ConfirmPlayersInLeague());
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'confirm',
              child: ListTile(
                leading: const Icon(Icons.done),
                title: Text(context.l10n.commonConfirm),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ];
    }
    if (state.status.isLoaded || state.status.isUpdating) {
      return [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'share') {
              _shareStandings(context, state.model?.name ?? '');
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: const Icon(Icons.share),
                title: Text(context.l10n.offlineShareStandings),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ];
    }
    return [];
  }

  Future<void> _shareStandings(BuildContext context, String leagueName) async {
    final shareText = context.l10n.offlineShareStandingsTitle(leagueName);
    final boundary =
        _tableKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final pngBytes = byteData.buffer.asUint8List();
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/league_standings.png');
    await file.writeAsBytes(pngBytes);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: shareText),
    );
  }

  Widget _leagueDetail(BuildContext context, LeagueDetailState state) {
    final colorScheme = Theme.of(context).colorScheme;
    if (state.status.isEmpty) {
      return AppEmptyState(
        icon: Icons.group_add_outlined,
        title: context.l10n.offlineLeagueNotSetupTitle,
        subtitle: context.l10n.offlineLeagueNotSetupSubtitle,
      );
    }
    if (state.status.isAddingPlayer) {
      return SelectPlayerView(
        enableSection: (players, enable) => BlocProvider.of<LeagueDetailBloc>(
          context,
        ).add(AddPlayersToLeague(players)),
      );
    }
    if (state.status.isError) {
      return AppEmptyState(
        icon: Icons.error_outline,
        title: context.l10n.commonErrorTitle,
        subtitle: context.l10n.offlineLoadLeagueFailed,
      );
    }
    if (state.status.isLoaded || state.status.isUpdating) {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              RepaintBoundary(
                key: _tableKey,
                child: Container(
                  color: colorScheme.surface,
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Text(
                          state.model?.name ?? '',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const TableView(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Expanded(child: MatchesView()),
            ],
          ),
        ),
      );
    }
    if (state.status.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.secondary),
      );
    }
    return const SizedBox.shrink();
  }
}
