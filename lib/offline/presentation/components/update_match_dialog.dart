import 'package:flutter/material.dart';
import 'package:game_note/offline/domain/entities/match_model.dart';

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
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // home
          Row(
            children: [
              ClipRRect(
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.model.home?.playerModel.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                widget.model.home?.playerModel.fullname ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 32,
                child: TextFormField(
                  //cursorColor: Colors.white,
                  controller: homeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 16),
          // away
          Row(
            children: [
              ClipRRect(
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.model.away?.playerModel.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                widget.model.away?.playerModel.fullname ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 32,
                child: TextFormField(
                  // cursorColor: Colors.white,
                  controller: awayController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      actions: [
        CloseButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        IconButton(
          onPressed: () {
            var home = int.tryParse(homeController.text);
            var away = int.tryParse(awayController.text);
            if (home == null || away == null) {
              return;
            }
            widget.callback(widget.model, home, away);
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.done),
        ),
      ],
    );
  }
}
