import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/teams_bloc.dart';

class OtherTeamsView extends StatelessWidget {
  const OtherTeamsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeamsBloc, TeamsState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            color: Colors.green[50],
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Danh sách đội',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  SearchAnchor(
                    // headerHeight: 0,
                    viewSide: const BorderSide(color: Colors.transparent),
                    viewElevation: 0,
                    isFullScreen: false,
                    viewBackgroundColor: Colors.green[100],
                    viewConstraints: BoxConstraints.tight(
                        Size(MediaQuery.of(context).size.width, 400)),
                    builder:
                        (BuildContext context, SearchController controller) {
                      return SearchBar(
                        backgroundColor: WidgetStatePropertyAll(
                            Colors.green.withValues(alpha: 0.5)),
                        constraints: BoxConstraints.tight(
                            Size(MediaQuery.of(context).size.width * 0.5, 40)),
                        elevation: const WidgetStatePropertyAll(0),
                        hintText: 'Tìm kiếm đội',
                        controller: controller,
                        onTap: () {
                          controller.openView();
                        },
                        onChanged: (_) {
                          controller.openView();
                        },
                        trailing: const [Icon(Icons.search)],
                      );
                    },
                    suggestionsBuilder:
                        (BuildContext context, SearchController controller) {
                      return List<ListTile>.generate(
                        5,
                        (int index) {
                          final String item = 'item $index';
                          return ListTile(
                            title: Text(item),
                            onTap: () {
                              controller.closeView(null);
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: state.otherTeams.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text('Chưa có đội nào, hãy tạo một đội mới.'),
                        ),
                      )
                    : ListView.builder(
                        itemCount: 20,
                        itemBuilder: (BuildContext context, int index) {
                          return ListTile(
                            title: Text('Đội ${index + 1}'),
                          );
                        },
                      ),
              )
            ],
          ),
        );
      },
    );
  }
}
