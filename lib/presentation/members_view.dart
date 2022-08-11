import 'package:flutter/material.dart';
import 'package:game_note/_old/model/player.dart';
import 'package:game_note/_old/views/components/player_view.dart';
import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/injection_container.dart';

class MembersView extends StatefulWidget {
  const MembersView({Key? key}) : super(key: key);

  @override
  State<MembersView> createState() => _MembersViewState();
}

class _MembersViewState extends State<MembersView> {
  late TextEditingController controller;
  String fullname = "";
  List<Player> players = [];
  @override
  void initState() {
    controller = TextEditingController();
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
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text("Fullname"),
                const SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: (string) {
                      setState(() {
                        fullname = string;
                      });
                    },
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: fullname.length > 2
                  ? () async {
                      var player =
                          Player(fullname: controller.text, level: "Noob");
                      await getIt<DatabaseManager>().insertPlayer(player);
                      controller.text = "";
                      setState(() {
                        fullname = "";
                      });
                      var newPlayers = await getIt<DatabaseManager>().players();
                      setState(() {
                        players = newPlayers;
                      });
                    }
                  : null,
              child: const Text("Add"),
            ),
            const SizedBox(height: 44),
            const Text("Players"),
            Expanded(
              child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    return Dismissible(
                      confirmDismiss: (direction) {
                        return Future.value(true);
                      },
                      key: Key(players[index].id.toString()),
                      onDismissed: (direction) async {
                        await getIt<DatabaseManager>()
                            .deletePlayer(players[index]);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Deleted ${players[index].fullname}',
                            ),
                          ),
                        );
                      },
                      background: Container(color: Colors.red),
                      child: PlayerView(
                        players[index],
                        onClick: null,
                        bold: true,
                      ),
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
