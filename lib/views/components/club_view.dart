import 'package:flutter/material.dart';
import 'package:game_note/model/club_model.dart';

class ClubView extends StatefulWidget {
  final ClubModel model;
  final Function(ClubModel)? onClick;
  const ClubView({
    Key? key,
    required this.model,
    this.onClick,
  }) : super(key: key);

  @override
  State<ClubView> createState() => _ClubViewState();
}

class _ClubViewState extends State<ClubView> {
  bool isSelected = false;
  @override
  void initState() {
    super.initState();
    isSelected = widget.model.isSelecting;
  }

  @override
  Widget build(BuildContext context) {
    print("build clubs ${widget.model.title}");
    return GestureDetector(
      onTap: widget.onClick == null
          ? null
          : () {
              widget.model.isSelecting = !widget.model.isSelecting;
              widget.onClick!(widget.model);
              setState(() {
                isSelected = widget.model.isSelecting;
              });
            },
      child: Container(
        margin: widget.onClick == null
            ? null
            : const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.model.isSelecting ? Colors.grey : Colors.white,
          border: Border.all(
            color: widget.model.isSelecting ? Colors.grey : Colors.white,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: Text(widget.model.title)),
      ),
    );
  }
}
