import 'package:flutter/material.dart';

class CreateTeamView extends StatelessWidget {
  const CreateTeamView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Text('Create Team'),
      ),
    );
  }
}
