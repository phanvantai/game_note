import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../offline/presentation/menu/components/menu_item_view.dart';
import 'bloc/app_bloc.dart';

class SwitchModeWidget extends StatelessWidget {
  const SwitchModeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) => MenuItemView(
        title: 'Cộng đồng',
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
