import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:game_note/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart';

class EsportLeagueSetting extends StatelessWidget {
  const EsportLeagueSetting({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<TournamentDetailBloc>(context);
    return ListView(
      children: [
        // dropdown to change league status
        ListTile(
          leading: const Icon(Icons.flag),
          title: const Text('Cập nhật trạng thái'),
          onTap: () {
            // show dialog to change league status
            showDialog(
              context: context,
              builder: (ctx) {
                return AlertDialog(
                  title: const Text('Thay đổi trạng thái giải đấu'),
                  content:
                      BlocBuilder<TournamentDetailBloc, TournamentDetailState>(
                    bloc: bloc,
                    builder: (ctx, state) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Chọn trạng thái mới cho giải đấu:'),
                        const SizedBox(height: 8),
                        DropdownButton<GNEsportLeagueStatus>(
                          value: GNEsportLeagueStatusExtension.fromString(
                              state.league.status),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            bloc.add(ChangeLeagueStatus(value));
                          },
                          items: GNEsportLeagueStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status.name),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () {
                        // submit league status
                        bloc.add(SubmitLeagueStatus());
                        Navigator.of(context).pop();
                      },
                      child: const Text('Lưu'),
                    ),
                  ],
                );
              },
            );
          },
        ),
        // delete league
        ListTile(
          leading: const Icon(
            Icons.delete,
            color: Colors.red,
          ),
          title: const Text('Xóa giải đấu'),
          onTap: () {
            // show dialog to confirm delete
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Xác nhận xóa giải đấu'),
                content:
                    const Text('Bạn có chắc chắn muốn xóa giải đấu này không?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () {
                      // delete league (inactive)
                      bloc.add(InactiveLeague());
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Xóa'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
