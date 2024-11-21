import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:game_note/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart';

import '../widgets/medal_widget.dart';

class EsportLeagueSetting extends StatelessWidget {
  const EsportLeagueSetting({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<TournamentDetailBloc>(context);
    return BlocBuilder<TournamentDetailBloc, TournamentDetailState>(
        builder: (context, state) => ListView(
              children: [
                // edit starting medals
                ListTile(
                  leading: const MedalWidget(size: 20, color: Colors.black87),
                  title: Text(
                      'Số lượng medal tối thiểu (${bloc.state.league?.startingMedals ?? '~'})'),
                  onTap: () {
                    final textController = TextEditingController()
                      ..text =
                          bloc.state.league?.startingMedals.toString() ?? '';
                    // show dialog to edit starting medals
                    showDialog(
                      context: context,
                      builder: (ctx) {
                        return AlertDialog(
                          title: const Text('Số lượng medal tối thiểu'),
                          content: BlocBuilder<TournamentDetailBloc,
                              TournamentDetailState>(
                            bloc: bloc,
                            builder: (ctx, state) => Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: textController,
                                  keyboardType: TextInputType.number,
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
                                // submit starting medals
                                final medals =
                                    int.tryParse(textController.text);
                                if (medals == null) {
                                  return;
                                }
                                bloc.add(UpdateStartingMedals(medals));
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
                // edit unit medals
                ListTile(
                  leading: const Icon(Icons.monetization_on),
                  title: Text(
                      'Giá trị mỗi medal (${bloc.state.league?.valueMedal ?? '~'})'),
                  onTap: () {
                    final textController = TextEditingController()
                      ..text = bloc.state.league?.valueMedal.toString() ?? '';
                    // show dialog to edit unit medals
                    showDialog(
                      context: context,
                      builder: (ctx) {
                        return AlertDialog(
                          title: const Text('Giá trị mỗi medal'),
                          content: BlocBuilder<TournamentDetailBloc,
                              TournamentDetailState>(
                            bloc: bloc,
                            builder: (ctx, state) => Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: textController,
                                  keyboardType: TextInputType.number,
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
                                // submit unit medals
                                final medals =
                                    int.tryParse(textController.text);
                                if (medals == null) {
                                  return;
                                }
                                bloc.add(UpdateUnitMedals(medals));
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
                          content: BlocBuilder<TournamentDetailBloc,
                              TournamentDetailState>(
                            bloc: bloc,
                            builder: (ctx, state) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Chọn trạng thái mới cho giải đấu:'),
                                const SizedBox(height: 8),
                                DropdownButton<GNEsportLeagueStatus>(
                                  value:
                                      GNEsportLeagueStatusExtension.fromString(
                                          state.league?.status),
                                  onChanged: (value) {
                                    if (value == null) {
                                      return;
                                    }
                                    bloc.add(ChangeLeagueStatus(value));
                                  },
                                  items:
                                      GNEsportLeagueStatus.values.map((status) {
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
                        content: const Text(
                            'Bạn có chắc chắn muốn xóa giải đấu này không?'),
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
                            },
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ));
  }
}
