import 'package:flutter/material.dart';
import 'package:game_note/_old/model/two_player_round.dart';
import 'package:game_note/presentation/solo_round/round_item_view.dart';
import 'package:game_note/presentation/solo_round/round_view.dart';
import 'package:game_note/presentation/solo_round/two_player_round_view.dart';
import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/injection_container.dart';

class SoloRoundView extends StatefulWidget {
  const SoloRoundView({Key? key}) : super(key: key);

  @override
  State<SoloRoundView> createState() => _SoloRoundViewState();
}

class _SoloRoundViewState extends State<SoloRoundView>
    with AutomaticKeepAliveClientMixin {
  List<TwoPlayerRound> rounds = [];
  @override
  void initState() {
    super.initState();
    getRounds();
  }

  Future<void> getRounds() async {
    var list = await getIt<DatabaseManager>().rounds();
    setState(() {
      rounds = list;
    });
    return;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _listRound(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewRound,
        tooltip: 'Add New Round',
        child: const Icon(Icons.add),
      ),
    );
  }

  _addNewRound() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RoundView(),
      ),
    );
  }

  _listRound() {
    return RefreshIndicator(
      child: ListView.builder(
        itemCount: rounds.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TwoPlayerRoundView(
                    twoPlayerRound: rounds[index],
                  ),
                ),
              );
            },
            child: RoundItemView(model: rounds[index]),
          );
        },
      ),
      onRefresh: getRounds,
    );
  }

  @override
  bool get wantKeepAlive => true;
}
