import 'package:flutter/material.dart';

class EsportLeagueSetting extends StatelessWidget {
  const EsportLeagueSetting({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              builder: (context) => AlertDialog(
                title: const Text('Thay đổi trạng thái giải đấu'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Chọn trạng thái mới cho giải đấu:'),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: 'upcoming',
                      onChanged: (value) {},
                      items: const [
                        DropdownMenuItem(
                          value: 'upcoming',
                          child: Text('Sắp diễn ra'),
                        ),
                        DropdownMenuItem(
                          value: 'ongoing',
                          child: Text('Đang diễn ra'),
                        ),
                        DropdownMenuItem(
                          value: 'finished',
                          child: Text('Đã kết thúc'),
                        ),
                      ],
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
                  TextButton(
                    onPressed: () {
                      // change league status
                      // BlocProvider.of<TournamentDetailBloc>(context)
                      //     .add(ChangeLeagueStatus());
                      Navigator.of(context).pop();
                    },
                    child: const Text('Lưu'),
                  ),
                ],
              ),
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
                      // delete league
                      // BlocProvider.of<TournamentDetailBloc>(context)
                      //     .add(DeleteLeague());
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
