import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';

import '../../../firebase/firestore/esport/group/gn_esport_group.dart';

class CreateEsportLeagueDialog extends StatefulWidget {
  final List<GNEsportGroup> groups;
  final Function(
    String name,
    String groupId,
    DateTime? startDate,
    DateTime? endDate,
    String description,
    bool rankPayoutEnabled,
    List<int> rankPayouts,
    int defaultMatchCost,
  )
  onAddLeague;
  const CreateEsportLeagueDialog({
    super.key,
    required this.groups,
    required this.onAddLeague,
  });

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

  bool rankPayoutEnabled = false;
  final TextEditingController rankPayoutsController = TextEditingController(
    text: '50000, 100000, 150000',
  );
  final TextEditingController defaultMatchCostController =
      TextEditingController(text: '50000');

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    rankPayoutsController.dispose();
    defaultMatchCostController.dispose();
    super.dispose();
  }

  List<int> _parseRankPayouts(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => int.tryParse(e) ?? 0)
        .where((v) => v > 0)
        .toList();
  }

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
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            startDate != null
                                ? DateFormat('dd/MM/yy').format(startDate!)
                                : 'Bắt đầu',
                            style: TextStyle(
                              color: startDate != null
                                  ? null
                                  : Theme.of(context).colorScheme.onSurface
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
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            endDate != null
                                ? DateFormat('dd/MM/yy').format(endDate!)
                                : 'Kết thúc',
                            style: TextStyle(
                              color: endDate != null
                                  ? null
                                  : Theme.of(context).colorScheme.onSurface
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
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: const Text('Chi phí (tuỳ chọn)'),
                leading: const Icon(Icons.payments_outlined),
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Tính tiền theo thứ hạng'),
                    subtitle: const Text(
                      'Hạng dưới góp tiền cho hạng nhất theo cấu hình',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: rankPayoutEnabled,
                    onChanged: (v) => setState(() => rankPayoutEnabled = v),
                  ),
                  if (rankPayoutEnabled) ...[
                    const SizedBox(height: 4),
                    TextField(
                      controller: rankPayoutsController,
                      keyboardType: TextInputType.number,
                      decoration: appInputDecoration(
                        context: context,
                        hintText: 'VD: 50000, 100000, 150000',
                        prefixIcon: Icons.format_list_numbered,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lần lượt: hạng 2, hạng 3, hạng 4… đóng cho hạng 1.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: defaultMatchCostController,
                    keyboardType: TextInputType.number,
                    decoration: appInputDecoration(
                      context: context,
                      hintText: 'Tiền mặc định mỗi trận (VND)',
                      prefixIcon: Icons.attach_money,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Số này sẽ được điền sẵn khi bật cost cho từng trận lúc nhập kết quả.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
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
            final parsedRankPayouts = rankPayoutEnabled
                ? _parseRankPayouts(rankPayoutsController.text)
                : <int>[];
            if (rankPayoutEnabled && parsedRankPayouts.isEmpty) {
              showToast('Nhập số tiền theo thứ hạng (VD: 50000, 100000)');
              return;
            }
            final defaultMatchCost =
                int.tryParse(defaultMatchCostController.text.trim()) ?? 50000;
            widget.onAddLeague(
              nameController.text,
              selectedGroup!.id,
              startDate,
              endDate,
              descriptionController.text,
              rankPayoutEnabled,
              parsedRankPayouts,
              defaultMatchCost,
            );
          },
          child: const Text('Tạo'),
        ),
      ],
    );
  }
}
