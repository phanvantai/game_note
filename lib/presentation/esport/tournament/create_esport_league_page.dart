import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/presentation/esport/tournament/cost/cost_config_form.dart';

import '../../../firebase/firestore/esport/group/gn_esport_group.dart';

typedef OnAddLeagueCallback = void Function(
  String name,
  String groupId,
  DateTime? startDate,
  DateTime? endDate,
  String description,
  bool rankPayoutEnabled,
  List<int> rankPayouts,
  int defaultMatchCost,
);

class CreateEsportLeaguePage extends StatefulWidget {
  final List<GNEsportGroup> groups;
  final OnAddLeagueCallback onAddLeague;

  const CreateEsportLeaguePage({
    super.key,
    required this.groups,
    required this.onAddLeague,
  });

  @override
  State<CreateEsportLeaguePage> createState() => _CreateEsportLeaguePageState();
}

class _CreateEsportLeaguePageState extends State<CreateEsportLeaguePage> {
  GNEsportGroup? selectedGroup;
  DateTime? startDate;
  DateTime? endDate;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final GlobalKey<CostConfigFormState> _costFormKey =
      GlobalKey<CostConfigFormState>();

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (selectedGroup == null) {
      showToast('Bạn cần chọn nhóm');
      return;
    }
    final cost = _costFormKey.currentState?.validateAndCollect();
    if (cost == null) return;
    widget.onAddLeague(
      nameController.text,
      selectedGroup!.id,
      startDate,
      endDate,
      descriptionController.text,
      cost.rankPayoutEnabled,
      cost.rankPayouts,
      cost.defaultMatchCost,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo giải đấu'),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('Tạo'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                decoration: appInputDecoration(
                  context: context,
                  hintText: 'Tên giải đấu',
                  prefixIcon: Icons.emoji_events_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                textInputAction: TextInputAction.next,
                decoration: appInputDecoration(
                  context: context,
                  hintText: 'Mô tả',
                  prefixIcon: Icons.description_outlined,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GNEsportGroup>(
                initialValue: selectedGroup,
                onChanged: (value) {
                  setState(() {
                    selectedGroup = value;
                  });
                },
                items: widget.groups.map((group) {
                  return DropdownMenuItem<GNEsportGroup>(
                    value: group,
                    child: Text(group.groupName),
                  );
                }).toList(),
                decoration: appInputDecoration(
                  context: context,
                  hintText: 'Chọn nhóm',
                  prefixIcon: Icons.group_outlined,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      hintText: 'Bắt đầu',
                      value: startDate,
                      onPicked: (d) => setState(() => startDate = d),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DatePickerField(
                      hintText: 'Kết thúc',
                      value: endDate,
                      onPicked: (d) => setState(() => endDate = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 20,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Chi phí',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CostConfigForm(
                key: _costFormKey,
                initialRankPayoutEnabled: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String hintText;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;

  const _DatePickerField({
    required this.hintText,
    required this.value,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (selected != null) onPicked(selected);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              value != null
                  ? DateFormat('dd/MM/yy').format(value!)
                  : hintText,
              style: TextStyle(
                color: value != null
                    ? null
                    : colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
