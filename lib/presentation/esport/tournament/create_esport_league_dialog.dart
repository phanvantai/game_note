import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';

import '../../../firebase/firestore/esport/group/gn_esport_group.dart';

class CreateEsportLeagueDialog extends StatefulWidget {
  final List<GNEsportGroup> groups;
  final Function(String name, String groupId, DateTime? startDate,
      DateTime? endDate, String description) onAddLeague;
  const CreateEsportLeagueDialog({
    Key? key,
    required this.groups,
    required this.onAddLeague,
  }) : super(key: key);

  @override
  State<CreateEsportLeagueDialog> createState() =>
      _CreateEsportLeagueDialogState();
}

class _CreateEsportLeagueDialogState extends State<CreateEsportLeagueDialog> {
  GNEsportGroup? selectedGroup;
  DateTime? startDate;
  DateTime? endDate;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tạo giải đấu'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: appInputDecoration(
                context: context,
                hintText: 'Tên giải đấu',
                prefixIcon: Icons.emoji_events_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: appInputDecoration(
                context: context,
                hintText: 'Mô tả',
                prefixIcon: Icons.description_outlined,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<GNEsportGroup>(
              value: selectedGroup,
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
                  child: GestureDetector(
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (selected != null) {
                        setState(() {
                          startDate = selected;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            startDate != null
                                ? DateFormat('dd/MM/yy').format(startDate!)
                                : 'Bắt đầu',
                            style: TextStyle(
                              color: startDate != null
                                  ? null
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (selected != null) {
                        setState(() {
                          endDate = selected;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            endDate != null
                                ? DateFormat('dd/MM/yy').format(endDate!)
                                : 'Kết thúc',
                            style: TextStyle(
                              color: endDate != null
                                  ? null
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            if (selectedGroup == null) {
              showToast('Bạn cần chọn nhóm');
              return;
            }
            widget.onAddLeague(
              nameController.text,
              selectedGroup!.id,
              startDate,
              endDate,
              descriptionController.text,
            );
          },
          child: const Text('Tạo'),
        ),
      ],
    );
  }
}
