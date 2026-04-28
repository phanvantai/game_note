import 'package:flutter/material.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';

/// Kết quả collect từ [CostConfigForm]. Tất cả số tiền là VND đầy đủ.
class CostConfigFormResult {
  final bool rankPayoutEnabled;
  final List<int> rankPayouts;
  final int defaultMatchCost;

  const CostConfigFormResult({
    required this.rankPayoutEnabled,
    required this.rankPayouts,
    required this.defaultMatchCost,
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

  const CostConfigForm({
    super.key,
    this.initialRankPayoutEnabled = false,
    this.initialRankPayouts = const [],
    this.initialDefaultMatchCost = 50000,
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

  @override
  void dispose() {
    _rankPayoutsController.dispose();
    _defaultMatchCostController.dispose();
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
      showToast('Nhập số tiền theo thứ hạng (VD: 50, 100)');
      return null;
    }
    final defaultMatchCost = (int.tryParse(
              _defaultMatchCostController.text.trim(),
            ) ??
            50) *
        1000;
    return CostConfigFormResult(
      rankPayoutEnabled: _rankPayoutEnabled,
      rankPayouts: parsedRankPayouts,
      defaultMatchCost: defaultMatchCost,
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
          title: const Text('Tính tiền theo thứ hạng'),
          subtitle: const Text(
            'Hạng dưới góp tiền cho hạng nhất theo cấu hình',
            style: TextStyle(fontSize: 11),
          ),
          value: _rankPayoutEnabled,
          onChanged: (v) => setState(() => _rankPayoutEnabled = v),
        ),
        if (_rankPayoutEnabled) ...[
          const SizedBox(height: 4),
          TextField(
            controller: _rankPayoutsController,
            keyboardType: TextInputType.number,
            decoration: appInputDecoration(
              context: context,
              hintText: 'VD: 50, 100, 150 (k VND)',
              prefixIcon: Icons.format_list_numbered,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lần lượt: hạng 2, hạng 3, hạng 4… đóng cho hạng 1.',
            style: textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _defaultMatchCostController,
          keyboardType: TextInputType.number,
          decoration: appInputDecoration(
            context: context,
            hintText: 'Tiền mặc định mỗi trận (k VND)',
            prefixIcon: Icons.attach_money,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Số này sẽ được điền sẵn khi bật cost cho từng trận lúc nhập kết quả.',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}
