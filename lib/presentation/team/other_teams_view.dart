import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';

import 'bloc/teams_bloc.dart';

class OtherTeamsView extends StatelessWidget {
  const OtherTeamsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<TeamsBloc, TeamsState>(
      builder: (context, state) {
        return AppCard(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Danh sách đội',
                      style: textTheme.titleSmall,
                    ),
                  ),
                  const Spacer(),
                  SearchAnchor(
                    viewSide: BorderSide.none,
                    viewElevation: 0,
                    isFullScreen: false,
                    viewBackgroundColor: colorScheme.surfaceContainerLow,
                    viewConstraints: BoxConstraints.tight(
                        Size(MediaQuery.of(context).size.width, 400)),
                    builder:
                        (BuildContext context, SearchController controller) {
                      return SearchBar(
                        backgroundColor: WidgetStatePropertyAll(
                            colorScheme.surfaceContainerHighest),
                        constraints: BoxConstraints.tight(
                            Size(MediaQuery.of(context).size.width * 0.5, 40)),
                        elevation: const WidgetStatePropertyAll(0),
                        hintText: 'Tìm kiếm đội',
                        hintStyle: WidgetStatePropertyAll(
                          textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        controller: controller,
                        onTap: () {
                          controller.openView();
                        },
                        onChanged: (_) {
                          controller.openView();
                        },
                        trailing: [
                          Icon(
                            Icons.search_outlined,
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ],
                      );
                    },
                    suggestionsBuilder:
                        (BuildContext context, SearchController controller) {
                      return List<ListTile>.generate(
                        5,
                        (int index) {
                          final String item = 'item $index';
                          return ListTile(
                            title: Text(
                              item,
                              style: textTheme.bodyMedium,
                            ),
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
              const SizedBox(height: 8),
              Expanded(
                child: state.otherTeams.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.groups_outlined,
                        title: 'Chưa có đội nào',
                        subtitle: 'Hãy tạo một đội mới.',
                      )
                    : ListView.builder(
                        itemCount: 20,
                        itemBuilder: (BuildContext context, int index) {
                          return ListTile(
                            leading: Icon(
                              Icons.groups_outlined,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            title: Text(
                              'Đội ${index + 1}',
                              style: textTheme.bodyMedium,
                            ),
                            trailing: Icon(
                              Icons.chevron_right_outlined,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                            ),
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
