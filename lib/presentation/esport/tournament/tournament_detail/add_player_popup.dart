import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:game_note/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:game_note/injection_container.dart';
import 'package:game_note/presentation/users/bloc/user_bloc.dart';
import 'package:game_note/presentation/users/user_item.dart';
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
    return BlocBuilder<UserBloc, UserState>(
      bloc: userBloc,
      builder: (userContext, userState) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            if (selectedUserIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8.0),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Đã chọn ${selectedUserIds.length} người:',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4, width: double.maxFinite),
                    Wrap(
                      spacing: 4,
                      children: selectedUserIds.map((userId) {
                        final user = userState.users
                            .where((u) => u.id == userId)
                            .firstOrNull;
                        if (user == null) return const SizedBox.shrink();
                        return Chip(
                          label: Text(user.displayName ??
                              user.email ??
                              user.phoneNumber ??
                              'Unknown'),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() {
                              selectedUserIds.remove(userId);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 250,
              width: double.maxFinite,
              child: ListView.separated(
                separatorBuilder: (context, index) => SizedBox(height: 0),
                itemCount: userState.users.length,
                itemBuilder: (ctx, index) {
                  final user = userState.users[index];
                  // ignore existing participants
                  if (widget.existingParticipants
                      .map((e) => e.userId)
                      .contains(user.id)) {
                    return const SizedBox.shrink();
                  }
                  final isSelected = selectedUserIds.contains(user.id);
                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.withValues(alpha: 0.2)
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
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.blue)
                          : const Icon(Icons.add_circle_outline),
                    ),
                  );
                },
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
          if (selectedUserIds.isNotEmpty)
            ElevatedButton(
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
