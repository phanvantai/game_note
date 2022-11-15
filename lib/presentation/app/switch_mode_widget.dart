import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/offline/menu/components/menu_item_view.dart';
import 'bloc/app_bloc.dart';

class SwitchModeWidget extends StatelessWidget {
  const SwitchModeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) => MenuItemView(
        title: 'Community Mode',
        icon: const Icon(Icons.accessibility),
        trailing: Switch(
          activeColor: Colors.orange,
          value: state.status.isCommunity,
          onChanged: (value) => context.read<AppBloc>().add(
              SwitchAppMode(value ? AppStatus.community : AppStatus.offline)),
        ),
      ),
    );
  }
}
