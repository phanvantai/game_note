import 'package:flutter/material.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_team.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Tạo trận đấu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<GNUser>(
            value: homeTeam,
            onChanged: (value) => setState(() => homeTeam = value),
            items: widget.users.map((team) {
              return DropdownMenuItem<GNUser>(
                value: team,
                child: EsportMatchTeam(user: team),
              );
            }).toList(),
            decoration: InputDecoration(
              hintText: 'Đội nhà',
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<GNUser>(
            value: awayTeam,
            onChanged: (value) => setState(() => awayTeam = value),
            items: widget.users.map((team) {
              return DropdownMenuItem<GNUser>(
                value: team,
                child: EsportMatchTeam(user: team),
              );
            }).toList(),
            decoration: InputDecoration(
              hintText: 'Đội khách',
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            if (homeTeam == null || awayTeam == null) {
              showToast('Vui lòng chọn đội');
              return;
            }
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
