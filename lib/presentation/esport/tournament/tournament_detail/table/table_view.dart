import 'package:flutter/material.dart';

class EsportTableView extends StatelessWidget {
  const EsportTableView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildCells(context, 20),
          ),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildRows(context, 20),
              ),
            ),
          )
        ],
      ),
    );
  }

  List<Widget> _buildCells(BuildContext context, int count) {
    return List.generate(
      count,
      (index) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            alignment: Alignment.center,
            width: 10.0,
            height: 60.0,
            color: Colors.white,
            margin: const EdgeInsets.all(4.0),
            child: Text("${index + 1}",
                style: Theme.of(context).textTheme.titleSmall),
          ),
          Container(
            alignment: Alignment.center,
            width: 120.0,
            height: 60.0,
            color: Colors.white,
            margin: const EdgeInsets.all(4.0),
            child: Text("${index + 1}",
                style: Theme.of(context).textTheme.titleSmall),
          )
        ],
      ),
    );
  }

  List<Widget> _buildRows(BuildContext context, int count) {
    return List.generate(
      count,
      (index) => Row(
        children: _buildCells(context, 5),
      ),
    );
  }
}
