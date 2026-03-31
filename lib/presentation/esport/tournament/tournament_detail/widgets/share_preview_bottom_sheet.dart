import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Displays a preview of the generated leaderboard screenshot inside a
/// beautiful bottom sheet, with a share button.
Future<void> showSharePreviewBottomSheet({
  required BuildContext context,
  required Uint8List imageBytes,
  required String leagueName,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SharePreviewSheet(
      imageBytes: imageBytes,
      leagueName: leagueName,
    ),
  );
}

class _SharePreviewSheet extends StatefulWidget {
  final Uint8List imageBytes;
  final String leagueName;

  const _SharePreviewSheet({
    required this.imageBytes,
    required this.leagueName,
  });

  @override
  State<_SharePreviewSheet> createState() => _SharePreviewSheetState();
}

class _SharePreviewSheetState extends State<_SharePreviewSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _doShare() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    // Capture RenderBox before any async gap to avoid BuildContext lifecycle issues.
    final box = context.findRenderObject() as RenderBox?;
    final originRect =
        box != null ? box.localToGlobal(Offset.zero) & box.size : null;
    try {
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/league_standings.png');
      await file.writeAsBytes(widget.imageBytes);
      await SharePlus.instance.share(
        ShareParams(
          title: 'Bảng xếp hạng - ${widget.leagueName}',
          files: [XFile(file.path)],
          sharePositionOrigin: originRect,
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.share_outlined, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Chia sẻ bảng xếp hạng',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Preview image
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ScaleTransition(
              scale: _scaleAnim,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: screenHeight * 0.52,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Image.memory(
                      widget.imageBytes,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Cancel
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
                const SizedBox(width: 12),
                // Share
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _sharing ? null : _doShare,
                    icon: _sharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.share_rounded, size: 20),
                    label:
                        Text(_sharing ? 'Đang chuẩn bị...' : 'Chia sẻ ngay'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
