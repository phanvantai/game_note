import 'package:flutter/material.dart';
import 'package:game_note/model/dump_leagues.dart';
import 'package:game_note/views/round/wheel_spinner_view.dart';
import 'package:sticky_headers/sticky_headers.dart';

class RandomView extends StatefulWidget {
  const RandomView({Key? key}) : super(key: key);

  @override
  State<RandomView> createState() => _RandomViewState();
}

class _RandomViewState extends State<RandomView> {
  bool picking = true;
  List<String> selecteds = <String>[];
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return picking ? _listLeague() : WheelSpinnerView(list: selecteds);
  }

  _listLeague() {
    return Column(
      children: [
        const SizedBox(height: 12),
        const Text("Selecting "),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: League.leagues.length,
            itemBuilder: (context, index) {
              return StickyHeader(
                header: Container(
                  height: 50.0,
                  color: Colors.greenAccent[700],
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.center,
                  child: Text(
                    League.leagues[index].title.toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                content: SizedBox(
                  height: 300,
                  child: ListView.builder(
                      itemCount: League.leagues[index].clubs.length,
                      itemBuilder: (context, index2) {
                        return Text(
                          League.leagues[index].clubs[index2],
                          style: TextStyle(color: Colors.black),
                        );
                      }),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
