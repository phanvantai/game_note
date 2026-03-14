import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/users/bloc/user_bloc.dart';
import 'package:pes_arena/presentation/users/user_item.dart';
import 'bloc/tournament_detail_bloc.dart';

class AddPlayerPopup extends StatefulWidget {
  final GNEsportLeague league;
  final List<GNEsportLeagueStat> existingParticipants;
  final TournamentDetailBloc tournamentDetailBloc;

  const AddPlayerPopup({
    Key? key,
    required this.league,
    required this.existingParticipants,
    required this.tournamentDetailBloc,
  }) : super(key: key);

  @override
  State<AddPlayerPopup> createState() => _AddPlayerPopupState();
}

class _AddPlayerPopupState extends State<AddPlayerPopup> {
  final Set<String> selectedUserIds = <String>{};
  late final UserBloc userBloc;

  @override
  void initState() {
    super.initState();
    userBloc = getIt<UserBloc>();
    userBloc.add(SearchUserByEsportGroup(widget.league.groupId, ''));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<UserBloc, UserState>(
      bloc: userBloc,
      builder: (userContext, userState) => AlertDialog(
        title: const Text('Thêm người chơi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedUserIds.isNotEmpty) ...[
              Text(
                'Đã chọn ${selectedUserIds.length} người:',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: selectedUserIds.map((userId) {
                  final user = userState.users
                      .where((u) => u.id == userId)
                      .firstOrNull;
                  if (user == null) return const SizedBox.shrink();
                  return Chip(
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(
                      user.displayName ??
                          user.email ??
                          user.phoneNumber ??
                          'Unknown',
                      style: textTheme.labelSmall,
                    ),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () {
                      setState(() => selectedUserIds.remove(userId));
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              height: 250,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: userState.users.length,
                itemBuilder: (ctx, index) {
                  final user = userState.users[index];
                  if (widget.existingParticipants
                      .map((e) => e.userId)
                      .contains(user.id)) {
                    return const SizedBox.shrink();
                  }
                  final isSelected = selectedUserIds.contains(user.id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.secondaryContainer
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: UserItem(
                      user: user,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedUserIds.remove(user.id);
                          } else {
                            selectedUserIds.add(user.id);
                          }
                        });
                      },
                      trailing: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: isSelected
                            ? colorScheme.secondary
                            : colorScheme.onSurface.withValues(alpha: 0.3),
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          if (selectedUserIds.isNotEmpty)
            FilledButton(
              onPressed: () {
                widget.tournamentDetailBloc.add(
                  AddMultipleParticipants(
                      widget.league.id, selectedUserIds.toList()),
                );
                Navigator.of(context).pop();
              },
              child: Text('Thêm ${selectedUserIds.length} người'),
            ),
        ],
      ),
    );
  }
}
