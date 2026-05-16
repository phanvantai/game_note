import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/common/smart_back.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';
import 'package:pes_arena/presentation/users/bloc/user_bloc.dart';

import '../../../users/user_item.dart';

class AddMemberPage extends StatelessWidget {
  final GroupDetailBloc bloc;
  final Set<String> currentMemberIds;
  final UserBloc? userBloc;

  const AddMemberPage({
    super.key,
    required this.bloc,
    required this.currentMemberIds,
    this.userBloc,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: _AddMemberView(
        currentMemberIds: currentMemberIds,
        userBloc: userBloc,
      ),
    );
  }
}

class _AddMemberView extends StatelessWidget {
  final Set<String> currentMemberIds;
  final UserBloc? userBloc;

  const _AddMemberView({required this.currentMemberIds, this.userBloc});

  @override
  Widget build(BuildContext context) {
    final ub = (userBloc ?? getIt<UserBloc>())..add(const SearchUser(''));
    return BlocProvider.value(
      value: ub,
      child: _AddMemberScaffold(currentMemberIds: currentMemberIds),
    );
  }
}

class _AddMemberScaffold extends StatelessWidget {
  final Set<String> currentMemberIds;

  const _AddMemberScaffold({required this.currentMemberIds});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: const SmartBackButton(),
        title: const Text('Thêm thành viên'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              autofocus: true,
              decoration: appInputDecoration(
                context: context,
                hintText: 'Tìm kiếm theo tên',
                prefixIcon: Icons.search,
              ),
              onChanged: (v) =>
                  context.read<UserBloc>().add(SearchUser(v)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _CreatePlaceholderTile(
              onConfirm: (name) {
                final groupId =
                    context.read<GroupDetailBloc>().state.group.id;
                context
                    .read<GroupDetailBloc>()
                    .add(AddPlaceholderMember(groupId, name));
                Navigator.of(context).pop();
              },
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
          Expanded(
            child: BlocBuilder<UserBloc, UserState>(
              builder: (context, userState) => ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: userState.users.length,
                itemBuilder: (ctx, index) {
                  final user = userState.users[index];
                  if (user.isCurrentUser ||
                      currentMemberIds.contains(user.id)) {
                    return const SizedBox.shrink();
                  }
                  return UserItem(
                    user: user,
                    onTap: () {
                      final groupId =
                          context.read<GroupDetailBloc>().state.group.id;
                      context
                          .read<GroupDetailBloc>()
                          .add(AddMember(groupId, user.id));
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatePlaceholderTile extends StatefulWidget {
  final void Function(String name) onConfirm;

  const _CreatePlaceholderTile({required this.onConfirm});

  @override
  State<_CreatePlaceholderTile> createState() =>
      _CreatePlaceholderTileState();
}

class _CreatePlaceholderTileState extends State<_CreatePlaceholderTile> {
  bool _expanded = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (!_expanded) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.secondary.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.person_add_alt_1_outlined,
                  size: 18, color: colorScheme.secondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tạo người chơi mới (placeholder)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 18, color: colorScheme.secondary),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_add_alt_1_outlined,
                  size: 18, color: colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                'Tạo người chơi mới',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Tên người chơi',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  _controller.clear();
                  setState(() => _expanded = false);
                },
                child: const Text('Huỷ'),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: _submit,
                child: const Text('Tạo'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    widget.onConfirm(name);
  }
}
