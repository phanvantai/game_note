import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

class WheelSpinnerView extends StatefulWidget {
  const WheelSpinnerView({Key? key}) : super(key: key);

  @override
  State<WheelSpinnerView> createState() => _WheelSpinnerViewState();
}

class _WheelSpinnerViewState extends State<WheelSpinnerView> {
  StreamController<int> selected = StreamController<int>();
  int value = -1;
  List<String> items = <String>[
    'Grogu',
    'Mace Windu',
    'Obi-Wan Kenobi',
    'Han Solo',
    'Luke Skywalker',
    'Darth Vader',
    'Yoda',
    'Ahsoka Tano',
  ];
  @override
  void dispose() {
    selected.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadValue();
  }

  loadValue() {
    // TODO: -
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width * 4 / 5;
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
                indicators: const <FortuneIndicator>[
                  FortuneIndicator(
                    alignment: Alignment.topCenter,
                    child: TriangleIndicator(
                      color: Colors.redAccent,
                    ),
                  ),
                ],
                selected: selected.stream,
                animateFirst: false,
                items: [
                  for (var it in items)
                    FortuneItem(
                      child: Text(it),
                      // style: FortuneItemStyle(
                      //   color: Colors.red, // <-- custom circle slice fill color
                      //   borderColor: Colors
                      //       .green, // <-- custom circle slice stroke color
                      //   borderWidth: 3, // <-- custom circle slice stroke width
                      // ),
                    ),
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
