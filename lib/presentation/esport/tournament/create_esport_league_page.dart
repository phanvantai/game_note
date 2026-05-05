import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    if (startDate != null && endDate != null &&
        startDate!.isAfter(endDate!)) {
      showToast('Ngày bắt đầu phải trước ngày kết thúc');
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.secondary.withValues(alpha: 0.16),
              theme.scaffoldBackgroundColor,
              colorScheme.primary.withValues(alpha: 0.06),
            ],
            stops: const [0, 0.46, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHero(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FormSectionCard(
                        icon: Icons.emoji_events_outlined,
                        title: 'Thông tin giải',
                        child: Column(
                          children: [
                            TextField(
                              controller: nameController,
                              textInputAction: TextInputAction.next,
                              decoration: appInputDecoration(
                                context: context,
                                hintText: 'Tên giải đấu',
                                prefixIcon: Icons.edit_outlined,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: descriptionController,
                              textInputAction: TextInputAction.next,
                              maxLines: 2,
                              decoration: appInputDecoration(
                                context: context,
                                hintText: 'Mô tả (tuỳ chọn)',
                                prefixIcon: Icons.description_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _FormSectionCard(
                        icon: Icons.group_outlined,
                        title: 'Nhóm & Thời gian',
                        child: Column(
                          children: [
                            DropdownButtonFormField<GNEsportGroup>(
                              initialValue: selectedGroup,
                              onChanged: (v) =>
                                  setState(() => selectedGroup = v),
                              items: widget.groups
                                  .map(
                                    (g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(g.groupName),
                                    ),
                                  )
                                  .toList(),
                              decoration: appInputDecoration(
                                context: context,
                                hintText: 'Chọn nhóm',
                                prefixIcon: Icons.groups_2_outlined,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _DatePickerField(
                                    hintText: 'Ngày bắt đầu',
                                    value: startDate,
                                    onPicked: (d) {
                                      setState(() {
                                        startDate = d;
                                        // Xoá end date nếu nó sớm hơn start date mới
                                        if (endDate != null &&
                                            d.isAfter(endDate!)) {
                                          endDate = null;
                                          showToast(
                                            'Đã xoá ngày kết thúc vì sớm hơn ngày bắt đầu',
                                          );
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _DatePickerField(
                                    hintText: 'Ngày kết thúc',
                                    value: endDate,
                                    onPicked: (d) {
                                      if (startDate != null &&
                                          d.isBefore(startDate!)) {
                                        showToast(
                                          'Ngày kết thúc phải sau ngày bắt đầu',
                                        );
                                        return;
                                      }
                                      setState(() => endDate = d);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _CollapsibleCostSection(costFormKey: _costFormKey),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          size: 20,
                        ),
                        label: const Text('Tạo giải đấu'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          _HeroIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SvgPicture.asset(
              'assets/svg/trophy-solid.svg',
              colorFilter: ColorFilter.mode(
                colorScheme.onSecondary,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tạo giải đấu',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable section card ─────────────────────────────────────────────────────

class _FormSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _FormSectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: colorScheme.secondary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Collapsible cost section ──────────────────────────────────────────────────

class _CollapsibleCostSection extends StatefulWidget {
  final GlobalKey<CostConfigFormState> costFormKey;

  const _CollapsibleCostSection({required this.costFormKey});

  @override
  State<_CollapsibleCostSection> createState() =>
      _CollapsibleCostSectionState();
}

class _CollapsibleCostSectionState extends State<_CollapsibleCostSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.payments_outlined,
                      size: 19,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cấu hình chi phí',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (!_expanded)
                          Text(
                            'Có thể cấu hình sau',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  Divider(
                    height: 1,
                    color: colorScheme.outline.withValues(alpha: 0.18),
                  ),
                  const SizedBox(height: 12),
                  CostConfigForm(
                    key: widget.costFormKey,
                    initialRankPayoutEnabled: false,
                  ),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

// ── Date picker field ─────────────────────────────────────────────────────────

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasValue = value != null;

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? colorScheme.secondary.withValues(alpha: 0.5)
                : colorScheme.outline.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: hasValue
                  ? colorScheme.secondary
                  : colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasValue
                    ? DateFormat('dd/MM/yy').format(value!)
                    : hintText,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: hasValue
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
            if (hasValue)
              Icon(
                Icons.check_circle_outline,
                size: 15,
                color: colorScheme.secondary,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Hero icon button ──────────────────────────────────────────────────────────

class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _HeroIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.onSurface, size: 20),
        ),
      ),
    );
  }
}
