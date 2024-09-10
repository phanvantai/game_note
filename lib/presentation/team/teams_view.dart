import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../routing.dart';
import 'bloc/teams_bloc.dart';

class TeamsView extends StatefulWidget {
  const TeamsView({Key? key}) : super(key: key);

  @override
  State<TeamsView> createState() => _TeamsViewState();
}

class _TeamsViewState extends State<TeamsView>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();

    context.read<TeamsBloc>().add(GetMyTeams());
    context.read<TeamsBloc>().add(GetOtherTeams());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SafeArea(
          child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              color: Colors.pink[50],
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 8),
              shape: Border.all(color: Colors.transparent),
              collapsedShape: Border.all(color: Colors.transparent),
              initiallyExpanded: true,
              trailing: ElevatedButton(
                child: const Text('Tạo đội'),
                onPressed: () {
                  Navigator.of(context).pushNamed(Routing.createTeam);
                },
              ),
              title: const Text(
                'Đội của tôi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: const [
                ListTile(
                  title: Text('Đội 1'),
                ),
                ListTile(
                  title: Text('Đội 2'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
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
                        builder: (BuildContext context,
                            SearchController controller) {
                          return SearchBar(
                            backgroundColor: WidgetStatePropertyAll(
                                Colors.green.withOpacity(0.5)),
                            constraints: BoxConstraints.tight(Size(
                                MediaQuery.of(context).size.width * 0.5, 40)),
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
                        suggestionsBuilder: (BuildContext context,
                            SearchController controller) {
                          return List<ListTile>.generate(
                            5,
                            (int index) {
                              final String item = 'item $index';
                              return ListTile(
                                title: Text(item),
                                onTap: () {
                                  setState(() {
                                    controller.closeView(item);
                                  });
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
                    child: ListView.builder(
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
            ),
          ),
        ],
      )),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
