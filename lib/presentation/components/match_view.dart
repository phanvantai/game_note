import 'package:flutter/material.dart';
import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/presentation/components/player_score_view.dart';

class MatchView extends StatefulWidget {
  final MatchModel model;
  final Function(MatchModel)? callback;
  const MatchView({Key? key, required this.model, this.callback})
      : super(key: key);

  @override
  State<MatchView> createState() => _MatchViewState();
}

class _MatchViewState extends State<MatchView> {
  bool editMode = false;
  int countScore = 0;
  late MatchModel matchModel;
  @override
  void initState() {
    super.initState();
    matchModel = widget.model;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: widget.model.status == false
          ? () {
              setState(() {
                editMode = true;
              });
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  PlayerScoreView(
                    model: widget.model.home,
                    editMode: editMode,
                    callback: editMode
                        ? (result) {
                            if (result.score != null) {
                              countScore++;
                              matchModel = MatchModel(
                                home: result,
                                away: matchModel.away,
                              );
                            }
                            if (countScore == 2 && widget.callback != null) {
                              setState(() {
                                editMode = false;
                              });
                              widget.callback!(MatchModel(
                                  home: matchModel.home,
                                  away: matchModel.away,
                                  status: true));
                              countScore = 0;
                            }
                          }
                        : null,
                  ),
                  PlayerScoreView(
                    model: widget.model.away,
                    editMode: editMode,
                    callback: editMode
                        ? (result) {
                            if (result.score != null) {
                              countScore++;
                              matchModel = MatchModel(
                                home: result,
                                away: matchModel.away,
                              );
                            }
                            if (countScore == 2 && widget.callback != null) {
                              setState(() {
                                editMode = false;
                              });
                              widget.callback!(MatchModel(
                                  home: matchModel.home,
                                  away: matchModel.away,
                                  status: true));
                              countScore = 0;
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
