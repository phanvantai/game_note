import 'package:flutter/material.dart';
import 'package:game_note/domain/entities/result_model.dart';

class PlayerScoreView extends StatefulWidget {
  final ResultModel model;
  final bool editMode;
  final Function(ResultModel)? callback;
  const PlayerScoreView(
      {Key? key, required this.model, required this.editMode, this.callback})
      : super(key: key);

  @override
  State<PlayerScoreView> createState() => _PlayerScoreViewState();
}

class _PlayerScoreViewState extends State<PlayerScoreView> {
  int? score;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          ClipRRect(
            child: Container(
              decoration: BoxDecoration(
                color: widget.model.playerModel.color,
                borderRadius: BorderRadius.circular(12),
              ),
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            widget.model.playerModel.fullname,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.normal,
            ),
          ),
          const Spacer(),
          if (!widget.editMode)
            Text(
              widget.model.score != null ? widget.model.score.toString() : '__',
              style: const TextStyle(fontWeight: FontWeight.bold),
            )
          else
            SizedBox(
              width: 24,
              height: 24,
              child: TextFormField(
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                cursorColor: Colors.white,
                onChanged: (value) {
                  setState(() {
                    score = int.tryParse(value);
                  });
                },
                onEditingComplete: () {
                  FocusScope.of(context).unfocus();
                  if (score != null && widget.callback != null) {
                    widget.callback!(ResultModel(
                        playerModel: widget.model.playerModel, score: score!));
                  }
                },
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
