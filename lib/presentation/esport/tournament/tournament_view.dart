import 'package:flutter/material.dart';

class TournamentView extends StatelessWidget {
  const TournamentView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const SafeArea(
        child: Center(
          child: Text('data'),
        ),
      ),
      floatingActionButton: ElevatedButton.icon(
        onPressed: () {},
        label: const Text('Tạo giải đấu'),
        icon: const Icon(Icons.add),
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(0),
          backgroundColor: WidgetStateProperty.all(Colors.red[100]),
        ),
      ),
    );
  }
}
