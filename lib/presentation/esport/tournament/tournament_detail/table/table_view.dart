import 'package:flutter/material.dart';

import 'stats_model.dart';

class EsportTableView extends StatelessWidget {
  const EsportTableView({Key? key}) : super(key: key);

  static const double tableRowHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    final list = List.of(StatsModel.mockStats);
    list.insert(0, StatsModel.header);
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildFixColumns(context, list),
          ),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildScrollableColumns(context, list),
              ),
            ),
          )
        ],
      ),
    );
  }

  List<Widget> _buildFixColumns(
      BuildContext context, List<StatsModel> listStats) {
    return List.generate(
      listStats.length,
      (index) {
        final stats = listStats[index];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ranking
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.grey,
                  width: 1.0,
                ),
              ),
              alignment: Alignment.center,
              width: 32.0,
              height: tableRowHeight,
              child: Text(
                stats.isHeader ? '#' : '$index',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Container(
              alignment: Alignment.center,
              width: 100.0,
              height: tableRowHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.grey,
                  width: 1.0,
                ),
              ),
              child: Text(stats.isHeader ? "Người chơi" : stats.name,
                  style: Theme.of(context).textTheme.titleSmall),
            )
          ],
        );
      },
    );
  }

  List<Widget> _buildScrollableColumns(
      BuildContext context, List<StatsModel> listStats) {
    return List.generate(
      listStats.length,
      (index) => Row(
        children: List.generate(
          listStats.length,
          (index) => Container(
            alignment: Alignment.center,
            width: 120.0,
            height: tableRowHeight,
            color: Colors.white,
            margin: const EdgeInsets.all(4.0),
            child: Text("${index + 1}",
                style: Theme.of(context).textTheme.titleSmall),
          ),
        ),
      ),
    );
  }
}
