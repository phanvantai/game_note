import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

import '../../model/dump_leagues.dart';

class WheelSpinnerView extends StatefulWidget {
  final List<String> list;
  const WheelSpinnerView({Key? key, required this.list}) : super(key: key);

  @override
  State<WheelSpinnerView> createState() => _WheelSpinnerViewState();
}

class _WheelSpinnerViewState extends State<WheelSpinnerView> {
  StreamController<int> selected = StreamController<int>();
  int value = -1;
  List<String> items = <String>[];

  @override
  void initState() {
    super.initState();
    setState(() {
      items = widget.list;
    });
  }

  loadValue() {
    var abc = League.leagues.map((e) => e.clubs).toList();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 4 / 5;
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          IconButton(
            onPressed: () {
              loadValue();
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 32),
          if (items.length > 1)
            GestureDetector(
              onTap: () {
                value = Fortune.randomInt(0, items.length);
                setState(() {
                  selected.add(value);
                });
              },
              child: SizedBox(
                height: width,
                width: width,
                child: FortuneWheel(
                  duration: const Duration(seconds: 3),
                  indicators: const <FortuneIndicator>[
                    FortuneIndicator(
                      alignment: Alignment.topCenter,
                      child: TriangleIndicator(
                        color: Colors.red,
                      ),
                    ),
                  ],
                  selected: selected.stream,
                  animateFirst: false,
                  items: [
                    for (var it in items) FortuneItem(child: Text(it)),
                  ],
                  onAnimationEnd: () {
                    if (value >= 0 && value < items.length) {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            content: Text(items[value]),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    items.removeAt(value);
                                  });
                                },
                                child: const Text("OK"),
                              )
                            ],
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
