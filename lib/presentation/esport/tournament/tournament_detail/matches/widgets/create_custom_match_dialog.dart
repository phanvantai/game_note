import 'package:flutter/material.dart';
import 'package:game_note/core/ultils.dart';
import 'package:game_note/firebase/firestore/user/gn_user.dart';
import 'package:game_note/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_team.dart';

class CreateCustomMatchDialog extends StatefulWidget {
  final List<GNUser> users;
  final Function(GNUser homeTeam, GNUser awayTeam) onMatchCreated;
  const CreateCustomMatchDialog({
    Key? key,
    required this.users,
    required this.onMatchCreated,
  }) : super(key: key);

  @override
  State<CreateCustomMatchDialog> createState() =>
      _CreateCustomMatchDialogState();
}

class _CreateCustomMatchDialogState extends State<CreateCustomMatchDialog> {
  GNUser? homeTeam;
  GNUser? awayTeam;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chọn 2 đội để tạo trận đấu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dropdown for picking Team 1
          DropdownButtonHideUnderline(
            child: DropdownButton<GNUser>(
              hint: const Text('Đội nhà'),
              // decoration: const InputDecoration(
              //   labelText: 'Đội nhà',
              //   border: OutlineInputBorder(
              //     borderSide: BorderSide.none,
              //   ),
              // ),
              value: homeTeam,
              onChanged: (value) {
                setState(() {
                  homeTeam = value;
                });
              },
              items: widget.users.map((team) {
                return DropdownMenuItem<GNUser>(
                  value: team,
                  child: EsportMatchTeam(user: team),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16.0),

          // Dropdown for picking Team 2
          DropdownButtonHideUnderline(
            child: DropdownButton<GNUser>(
              // decoration: const InputDecoration(
              //   labelText: 'Đội khách',
              //   border: OutlineInputBorder(
              //     borderSide: BorderSide.none,
              //   ),
              // ),
              hint: const Text('Đội khách'),
              value: awayTeam,
              onChanged: (value) {
                setState(() {
                  awayTeam = value;
                });
              },
              items: widget.users.map((team) {
                return DropdownMenuItem<GNUser>(
                  value: team,
                  child: EsportMatchTeam(user: team),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            // check if both teams are selected
            if (homeTeam == null || awayTeam == null) {
              showToast('Vui lòng chọn đội');
              return;
            }

            // check if both teams are different
            if (homeTeam == awayTeam) {
              showToast('Vui lòng chọn 2 đội khác nhau');
              return;
            }

            widget.onMatchCreated(homeTeam!, awayTeam!);
          },
          child: const Text('Tạo trận đấu'),
        ),
      ],
    );
  }
}
