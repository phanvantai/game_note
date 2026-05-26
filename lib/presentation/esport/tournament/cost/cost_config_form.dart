import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/l10n/l10n.dart';

/// Sinh các preset gợi ý phân chia thưởng (đơn vị k VND) dựa theo số người tham gia.
///
/// Trả về danh sách preset, mỗi preset là [List<int>] các giá trị k VND.
/// Trả về rỗng nếu [participantCount] < 2.
List<List<int>> generateRankPayoutPresets(int participantCount) {
  if (participantCount < 2) return [];
  final slots = participantCount - 1;
  final candidates = [
    List.generate(slots, (i) => (i + 1) * 50), // 50, 100, 150, ...
    List.generate(slots, (i) => 100 + i * 50), // 100, 150, 200, ...
    List.generate(slots, (i) => (i + 1) * 100), // 100, 200, 300, ...
  ];
  final seen = <String>{};
  return candidates.where((p) => seen.add(p.join(','))).toList();
}

/// Kết quả collect từ [CostConfigForm]. Tất cả số tiền là VND đầy đủ.
class CostConfigFormResult {
  final bool rankPayoutEnabled;
  final List<int> rankPayouts;
  final int defaultMatchCost;
  final bool defaultPerGoalEnabled;
  final int defaultCostPerGoal;

  const CostConfigFormResult({
    required this.rankPayoutEnabled,
    required this.rankPayouts,
    required this.defaultMatchCost,
    required this.defaultPerGoalEnabled,
    required this.defaultCostPerGoal,
  });
}

/// Form 3 field cấu hình chi phí giải đấu (switch + rank payouts + default match cost).
///
/// Input/display dùng đơn vị nghìn đồng (k VND), giá trị trả ra là VND đầy đủ.
/// Parent giữ [GlobalKey<CostConfigFormState>] và gọi [CostConfigFormState.validateAndCollect]
/// khi user bấm Save — null nghĩa là validation fail (form đã tự toast).
class CostConfigForm extends StatefulWidget {
  final bool initialRankPayoutEnabled;

  /// VND. Rỗng ⇒ dùng placeholder mặc định (50, 100, 150).
  final List<int> initialRankPayouts;

  /// VND.
  final int initialDefaultMatchCost;

  /// Default toggle "tiền theo hiệu số bàn thắng".
  final bool initialDefaultPerGoalEnabled;

  /// VND/bàn — tiền cộng thêm theo hiệu số bàn thắng.
  final int initialDefaultCostPerGoal;

  /// Số người tham gia giải đấu. Dùng để sinh preset gợi ý (0 = không gợi ý).
  final int participantCount;

  /// Cup / Full mode: ẩn preset, thay label + mô tả thành bracket ranking.
  final bool isBracketMode;

  const CostConfigForm({
    super.key,
    this.initialRankPayoutEnabled = false,
    this.initialRankPayouts = const [],
    this.initialDefaultMatchCost = 50000,
    this.initialDefaultPerGoalEnabled = false,
    this.initialDefaultCostPerGoal = 50000,
    this.participantCount = 0,
    this.isBracketMode = false,
  });

  @override
  State<CostConfigForm> createState() => CostConfigFormState();
}

class CostConfigFormState extends State<CostConfigForm> {
  late bool _rankPayoutEnabled = widget.initialRankPayoutEnabled;
  late final TextEditingController _rankPayoutsController =
      TextEditingController(
        text: widget.initialRankPayouts.isEmpty
            ? '50, 100, 150'
            : widget.initialRankPayouts.map((v) => v ~/ 1000).join(', '),
      );
  late final TextEditingController _defaultMatchCostController =
      TextEditingController(
        text: (widget.initialDefaultMatchCost ~/ 1000).toString(),
      );
  late bool _defaultPerGoalEnabled = widget.initialDefaultPerGoalEnabled;
  late final TextEditingController _defaultCostPerGoalController =
      TextEditingController(
        text: (widget.initialDefaultCostPerGoal ~/ 1000).toString(),
      );

  @override
  void dispose() {
    _rankPayoutsController.dispose();
    _defaultMatchCostController.dispose();
    _defaultCostPerGoalController.dispose();
    super.dispose();
  }

  /// Input là số nghìn đồng (k). Trả về danh sách VND.
  List<int> _parseRankPayouts(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => int.tryParse(e) ?? 0)
        .where((v) => v > 0)
        .map((v) => v * 1000)
        .toList();
  }

  /// Validate + thu thập giá trị. Trả về null nếu invalid (đã toast).
  CostConfigFormResult? validateAndCollect() {
    final parsedRankPayouts = _rankPayoutEnabled
        ? _parseRankPayouts(_rankPayoutsController.text)
        : <int>[];
    if (_rankPayoutEnabled && parsedRankPayouts.isEmpty) {
      showToast(context.l10n.costRankPayoutRequired);
      return null;
    }
    final defaultMatchCost =
        (int.tryParse(_defaultMatchCostController.text.trim()) ?? 50) * 1000;
    final defaultCostPerGoal = _defaultPerGoalEnabled
        ? (int.tryParse(_defaultCostPerGoalController.text.trim()) ?? 50) * 1000
        : 0;
    return CostConfigFormResult(
      rankPayoutEnabled: _rankPayoutEnabled,
      rankPayouts: parsedRankPayouts,
      defaultMatchCost: defaultMatchCost,
      defaultPerGoalEnabled: _defaultPerGoalEnabled,
      defaultCostPerGoal: defaultCostPerGoal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            widget.isBracketMode
                ? context.l10n.costBracketPayoutTitle
                : context.l10n.costRankPayoutTitle,
          ),
          subtitle: Text(
            widget.isBracketMode
                ? context.l10n.costBracketPayoutSubtitle
                : context.l10n.costRankPayoutSubtitle,
            style: const TextStyle(fontSize: 11),
          ),
          value: _rankPayoutEnabled,
          onChanged: (v) => setState(() => _rankPayoutEnabled = v),
        ),
        if (_rankPayoutEnabled) ...[
          const SizedBox(height: 4),
          if (!widget.isBracketMode)
            _RankPayoutPresets(
              participantCount: widget.participantCount,
              onSelect: (label) =>
                  setState(() => _rankPayoutsController.text = label),
            ),
          TextField(
            controller: _rankPayoutsController,
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,\s]')),
            ],
            decoration: appInputDecoration(
              context: context,
              hintText: context.l10n.costPayoutHint,
              prefixIcon: Icons.format_list_numbered,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.isBracketMode
                ? context.l10n.costBracketPayoutOrder
                : context.l10n.costRankPayoutOrder,
            style: textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _defaultMatchCostController,
          keyboardType: TextInputType.number,
          decoration: appInputDecoration(
            context: context,
            hintText: context.l10n.costDefaultMatchCostHint,
            prefixIcon: Icons.attach_money,
          ),
        ),
        const SizedBox(height: 4),
        Text(context.l10n.costDefaultMatchCostHelp, style: textTheme.bodySmall),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(context.l10n.costDefaultPerGoalTitle),
          subtitle: Text(
            context.l10n.costDefaultPerGoalSubtitle,
            style: const TextStyle(fontSize: 11),
          ),
          value: _defaultPerGoalEnabled,
          onChanged: (v) => setState(() => _defaultPerGoalEnabled = v),
        ),
        if (_defaultPerGoalEnabled) ...[
          TextField(
            controller: _defaultCostPerGoalController,
            keyboardType: TextInputType.number,
            decoration: appInputDecoration(
              context: context,
              hintText: context.l10n.costPerGoalHint,
              prefixIcon: Icons.sports_soccer,
            ),
          ),
          const SizedBox(height: 4),
          Text(context.l10n.costPerGoalHelp, style: textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _RankPayoutPresets extends StatelessWidget {
  final int participantCount;
  final void Function(String label) onSelect;

  const _RankPayoutPresets({
    required this.participantCount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final presets = generateRankPayoutPresets(participantCount);
    if (presets.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.costSuggestions,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: presets.map((preset) {
            final label = preset.join(', ');
            return ActionChip(
              label: Text(
                context.l10n.costPresetAmountLabel(label),
                style: const TextStyle(fontSize: 12),
              ),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              onPressed: () => onSelect(label),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}
