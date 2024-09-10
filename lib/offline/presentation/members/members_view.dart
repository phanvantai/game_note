import 'package:flutter/material.dart';
import 'package:game_note/offline/domain/entities/player_model.dart';
import 'package:game_note/offline/presentation/components/player_view.dart';
import 'package:game_note/offline/data/database/database_manager.dart';
import 'package:game_note/injection_container.dart';

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
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white70,
      appBar: AppBar(
        title: const Text('Người chơi'),
        backgroundColor: Colors.white70,
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: players.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có người chơi nào.\nBấm nút + bên dưới để thêm người chơi.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
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
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
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
                      const SizedBox(height: 16),
                ),
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
