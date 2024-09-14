import 'package:equatable/equatable.dart';

class StatsModel extends Equatable {
  final String name;
  final String photoUrl;
  final int matchesPlayed;
  final int win;
  final int lose;
  final int draw;
  final int goalsFor;
  final int goalsAgainst;

  const StatsModel({
    required this.name,
    required this.photoUrl,
    required this.matchesPlayed,
    required this.win,
    required this.lose,
    required this.draw,
    required this.goalsFor,
    required this.goalsAgainst,
  });

  StatsModel copyWith({
    String? name,
    String? photoUrl,
    int? matchesPlayed,
    int? win,
    int? lose,
    int? draw,
    int? goalsFor,
    int? goalsAgainst,
  }) {
    return StatsModel(
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      win: win ?? this.win,
      lose: lose ?? this.lose,
      draw: draw ?? this.draw,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
    );
  }

  @override
  List<Object?> get props => [
        name,
        photoUrl,
        matchesPlayed,
        win,
        lose,
        draw,
        goalsFor,
        goalsAgainst,
      ];

  static List<StatsModel> mockStats = [
    const StatsModel(
      name: 'name',
      photoUrl: 'photoUrl',
      matchesPlayed: 1,
      win: 1,
      lose: 0,
      draw: 0,
      goalsFor: 1,
      goalsAgainst: 0,
    ),
  ];
  static const header = StatsModel(
    name: 'Header',
    photoUrl: '',
    matchesPlayed: 0,
    win: 0,
    lose: 0,
    draw: 0,
    goalsFor: 0,
    goalsAgainst: 0,
  );

  bool get isHeader => name == 'Header';
}
