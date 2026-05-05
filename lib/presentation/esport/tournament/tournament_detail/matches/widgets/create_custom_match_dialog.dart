import 'package:flutter/material.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

import '../../../../../../widgets/gn_circle_avatar.dart';

class CreateCustomMatchDialog extends StatefulWidget {
  final List<GNUser> users;
  final Function(GNUser homeTeam, GNUser awayTeam) onMatchCreated;
  const CreateCustomMatchDialog({
    super.key,
    required this.users,
    required this.onMatchCreated,
  });

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
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<GNUser>(
              initialValue: homeTeam,
              isExpanded: true,
              menuMaxHeight: 320,
              onChanged: (value) => setState(() => homeTeam = value),
              items: widget.users.map((team) {
                return DropdownMenuItem<GNUser>(
                  value: team,
                  child: _TeamOption(user: team),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<GNUser>(
              initialValue: awayTeam,
              isExpanded: true,
              menuMaxHeight: 320,
              onChanged: (value) => setState(() => awayTeam = value),
              items: widget.users.map((team) {
                return DropdownMenuItem<GNUser>(
                  value: team,
                  child: _TeamOption(user: team),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
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

class _TeamOption extends StatelessWidget {
  final GNUser user;

  const _TeamOption({required this.user});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = user.displayName ?? user.email ?? user.phoneNumber ?? user.id;

    return Row(
      children: [
        GNCircleAvatar(photoUrl: user.photoUrl, size: 28),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
