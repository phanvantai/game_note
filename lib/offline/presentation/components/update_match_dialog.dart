import 'package:flutter/material.dart';
import 'package:pes_arena/offline/domain/entities/match_model.dart';

class UpdateMatchDialog extends StatefulWidget {
  final MatchModel model;
  final Function(MatchModel model, int homeScore, int awayScore) callback;
  const UpdateMatchDialog(
      {Key? key, required this.model, required this.callback})
      : super(key: key);

  @override
  State<UpdateMatchDialog> createState() => _UpdateMatchDialogState();
}

class _UpdateMatchDialogState extends State<UpdateMatchDialog> {
  TextEditingController homeController = TextEditingController();
  TextEditingController awayController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('Cập nhật tỉ số'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // home
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: widget.model.home?.playerModel.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.model.home?.playerModel.fullname ?? '',
                  style: textTheme.bodyLarge,
                ),
              ),
              SizedBox(
                width: 48,
                child: TextFormField(
                  controller: homeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.secondary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // away
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: widget.model.away?.playerModel.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.model.away?.playerModel.fullname ?? '',
                  style: textTheme.bodyLarge,
                ),
              ),
              SizedBox(
                width: 48,
                child: TextFormField(
                  controller: awayController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.secondary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            var home = int.tryParse(homeController.text);
            var away = int.tryParse(awayController.text);
            if (home == null || away == null) {
              return;
            }
            widget.callback(widget.model, home, away);
            Navigator.of(context).pop();
          },
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
