import 'package:game_note/model/club_model.dart';

class LeagueModel {
  final String title;
  final List<ClubModel> clubs;

  LeagueModel(this.title, this.clubs);

  static List<LeagueModel> leagues = [
    epl,
    laliga,
    seriea,
    bundesliga,
    eredivisie
  ];

  static LeagueModel epl = LeagueModel("EPL", [
    ClubModel("Manchester City"),
    ClubModel("Liverpool"),
    ClubModel("Chelsea"),
    ClubModel("Tottenham"),
    ClubModel("Arsenal"),
    ClubModel("Manchester United"),
  ]);
  static LeagueModel laliga = LeagueModel("Laliga", [
    ClubModel("Real Madrid"),
    ClubModel("Barcelona"),
    ClubModel("Atletico Madrid"),
    ClubModel("Sevilla"),
  ]);
  static LeagueModel seriea = LeagueModel("Serie A", [
    ClubModel("AC Milan"),
    ClubModel("Inter Milan"),
    ClubModel("Napoli"),
    ClubModel("Juventus"),
    ClubModel("Roma"),
    ClubModel("Atalanta"),
  ]);
  static LeagueModel bundesliga = LeagueModel("Bundesliga", [
    ClubModel("Bayern Munich"),
    ClubModel("Dortmund"),
    ClubModel("Bayer Leverkusen"),
    ClubModel("Leipzig"),
  ]);
  static LeagueModel ligue1 = LeagueModel("Ligue 1", [
    ClubModel("PSG"),
    ClubModel("Marseille"),
    ClubModel("Monaco"),
    ClubModel("Lyon"),
  ]);
  static LeagueModel eredivisie = LeagueModel("Eredivisie", [
    ClubModel("Ajax"),
    ClubModel("PSV"),
  ]);
}
