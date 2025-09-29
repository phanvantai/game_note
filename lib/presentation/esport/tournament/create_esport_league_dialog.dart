import 'package:flutter/material.dart';
import 'package:pes_arena/core/ultils.dart';

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
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tạo giải đấu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Tên giải đấu'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(labelText: 'Mô tả'),
          ),
          const SizedBox(height: 8),
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
            decoration: const InputDecoration(labelText: 'Nhóm'),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        ).then((selectedDate) {
                          if (selectedDate != null) {
                            setState(() {
                              startDateController.text =
                                  selectedDate.toString();
                              startDate = selectedDate;
                            });
                          }
                        });
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: startDateController,
                          decoration:
                              const InputDecoration(hintText: 'Ngày bắt đầu'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        ).then((selectedDate) {
                          if (selectedDate != null) {
                            setState(() {
                              endDateController.text =
                                  selectedDate.toIso8601String();
                              endDate = selectedDate;
                            });
                          }
                        });
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: endDateController,
                          decoration:
                              const InputDecoration(hintText: 'Ngày kết thúc'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            // name tournament is not required anymore
            // if (nameController.text.isEmpty) {
            //   showToast('Tên giải đấu không được để trống');
            //   return;
            // }
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
