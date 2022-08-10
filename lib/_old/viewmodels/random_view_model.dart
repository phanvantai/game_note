import 'package:flutter/material.dart';

import '../model/dump_leagues.dart';

class RandomWheelViewModel extends ChangeNotifier {
  bool _picking = true;
  List<LeagueModel> _listLeague = [];

  bool get picking => _picking;
  List<LeagueModel> get listLeague => _listLeague;

  RandomWheelViewModel() {
    setLeagues(LeagueModel.leagues);
  }

  setPicking(bool picking) async {
    _picking = picking;
    notifyListeners();
  }

  setLeagues(List<LeagueModel> list) async {
    _listLeague = list;
    notifyListeners();
  }

  List<String> get listSelected {
    List<String> abc = [];
    for (var leages in listLeague) {
      abc.addAll(leages.clubs
          .where((element) => element.isSelecting == true)
          .map((e) => e.title));
    }
    return abc;
  }

  updateSelection() {
    notifyListeners();
  }
}
