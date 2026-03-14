import 'package:flutter/material.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/offline/domain/entities/player_model.dart';
import 'package:pes_arena/offline/presentation/components/player_view.dart';
import 'package:pes_arena/offline/data/database/database_manager.dart';
import 'package:pes_arena/injection_container.dart';

import 'add_player_dialog.dart';

class MembersView extends StatefulWidget {
  const MembersView({Key? key}) : super(key: key);

  @override
  State<MembersView> createState() => _MembersViewState();
}

class _MembersViewState extends State<MembersView>
    with AutomaticKeepAliveClientMixin<MembersView> {
  List<PlayerModel> players = [];
  @override
  void initState() {
    super.initState();
    loadPlayer();
  }

  void loadPlayer() async {
    var newPlayers = await getIt<DatabaseManager>().players();
    setState(() {
      players = newPlayers;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Người chơi'),
      ),
      body: SafeArea(
        child: players.isEmpty
            ? const AppEmptyState(
                icon: Icons.person_outline,
                title: 'Chưa có người chơi nào.',
                subtitle: 'Bấm nút + bên dưới để thêm người chơi.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: players.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    direction: DismissDirection.endToStart,
                    key: Key(players[index].id.toString()),
                    onDismissed: (direction) {
                      getIt<DatabaseManager>()
                          .deletePlayer(players[index])
                          .then((value) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã xóa ${players[index].fullname}',
                            ),
                          ),
                        );
                        loadPlayer();
                      });
                    },
                    confirmDismiss: (direction) {
                      return Future.value(false);
                    },
                    background: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: Icon(
                        Icons.delete_outline,
                        color: colorScheme.onError,
                      ),
                    ),
                    child: PlayerView(
                      players[index],
                      onClick: null,
                      bold: true,
                    ),
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_player',
        onPressed: _addNewPlayer,
        tooltip: 'Thêm người chơi',
        child: const Icon(Icons.add),
      ),
    );
  }

  _addNewPlayer() {
    showDialog(
      context: context,
      builder: (_) => AddPlayerDialog(
        callback: () async {
          loadPlayer();
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
