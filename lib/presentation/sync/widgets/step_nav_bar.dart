import 'package:flutter/material.dart';

/// Sticky bottom nav cho từng bước sync. Luôn hiện cả Previous + Next để
/// flow rõ ràng — disabled khi không hợp lệ thay vì ẩn.
class StepNavBar extends StatelessWidget {
  const StepNavBar({
    super.key,
    required this.onPrevious,
    required this.onNext,
    this.previousLabel = 'Quay lại',
    required this.nextLabel,
    this.nextKey,
    this.previousKey,
  });

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final String previousLabel;
  final String nextLabel;
  final Key? nextKey;
  final Key? previousKey;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: previousKey,
                  onPressed: onPrevious,
                  child: Text(previousLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: nextKey,
                  onPressed: onNext,
                  child: Text(nextLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
