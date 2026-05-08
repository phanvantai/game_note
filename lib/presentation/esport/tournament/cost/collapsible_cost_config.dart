import 'package:flutter/material.dart';
import 'cost_config_form.dart';

class CollapsibleCostConfig extends StatefulWidget {
  final GlobalKey<CostConfigFormState> formKey;
  final bool isBracketMode;
  final bool initialRankPayoutEnabled;
  final List<int> initialRankPayouts;
  final int initialDefaultMatchCost;
  final int participantCount;
  /// Widget rendered at the bottom when expanded (e.g. a save button).
  /// Pass null to omit (create flow).
  final Widget? action;
  /// Subtitle shown in the header when collapsed. Pass null to omit.
  final String? subtitle;

  const CollapsibleCostConfig({
    super.key,
    required this.formKey,
    this.isBracketMode = false,
    this.initialRankPayoutEnabled = false,
    this.initialRankPayouts = const [],
    this.initialDefaultMatchCost = 50 * 1000,
    this.participantCount = 0,
    this.action,
    this.subtitle,
  });

  @override
  State<CollapsibleCostConfig> createState() => _CollapsibleCostConfigState();
}

class _CollapsibleCostConfigState extends State<CollapsibleCostConfig> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.28)),
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
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        if (!_expanded && widget.subtitle != null)
                          Text(
                            widget.subtitle!,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    height: 1,
                    color: colorScheme.outline.withValues(alpha: 0.18),
                  ),
                  const SizedBox(height: 12),
                  CostConfigForm(
                    key: widget.formKey,
                    isBracketMode: widget.isBracketMode,
                    initialRankPayoutEnabled: widget.initialRankPayoutEnabled,
                    initialRankPayouts: widget.initialRankPayouts,
                    initialDefaultMatchCost: widget.initialDefaultMatchCost,
                    participantCount: widget.participantCount,
                  ),
                  if (widget.action != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: widget.action!,
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
