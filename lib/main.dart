import 'package:flutter/material.dart';
import 'package:game_note/_old/model/two_player_round.dart';
import 'package:game_note/_old/viewmodels/random_view_model.dart';
import 'package:game_note/_old/views/add_player_view.dart';
import 'package:game_note/_old/views/round/round_view.dart';
import 'package:game_note/_old/views/round/two_player_round_view.dart';
import 'package:game_note/core/constants/constants.dart';
import 'package:game_note/injection_container.dart' as di;
import 'package:provider/provider.dart';

import 'core/database/database_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  await di.getIt<DatabaseManager>().open();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => RandomWheelViewModel()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(title: 'GameNote'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<TwoPlayerRound> rounds = [];
  @override
  void initState() {
    super.initState();
    getRounds();
  }

  Future<void> getRounds() async {
    var list = await di.getIt<DatabaseManager>().rounds();
    setState(() {
      rounds = list;
    });
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddPlayerView(),
                ),
              );
            },
            icon: const Icon(Icons.person_add),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RoundView(),
                  ),
                );
              },
              child: const Text("New Round"),
            ),
            const Divider(height: 16, color: Colors.black),
            Expanded(child: _listRound()),
          ],
        ),
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
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                rounds[index].name ?? "No title",
                style: boldTextStyle,
              ),
            ),
          );
        },
      ),
      onRefresh: getRounds,
    );
  }
}
