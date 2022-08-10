import 'club_model.dart';

class LeagueModel {
  final String title;
  final List<ClubOldModel> clubs;

  LeagueModel(this.title, this.clubs);

  static List<LeagueModel> leagues = [
    epl,
    laliga,
    seriea,
    bundesliga,
    eredivisie
  ];

  static LeagueModel epl = LeagueModel("EPL", [
    ClubOldModel("Manchester City"),
    ClubOldModel("Liverpool"),
    ClubOldModel("Chelsea"),
    ClubOldModel("Tottenham"),
    ClubOldModel("Arsenal"),
    ClubOldModel("Manchester United"),
  ]);
  static LeagueModel laliga = LeagueModel("Laliga", [
    ClubOldModel("Real Madrid"),
    ClubOldModel("Barcelona"),
    ClubOldModel("Atletico Madrid"),
    ClubOldModel("Sevilla"),
  ]);
  static LeagueModel seriea = LeagueModel("Serie A", [
    ClubOldModel("AC Milan"),
    ClubOldModel("Inter Milan"),
    ClubOldModel("Napoli"),
    ClubOldModel("Juventus"),
    ClubOldModel("Roma"),
    ClubOldModel("Atalanta"),
  ]);
  static LeagueModel bundesliga = LeagueModel("Bundesliga", [
    ClubOldModel("Bayern Munich"),
    ClubOldModel("Dortmund"),
    ClubOldModel("Bayer Leverkusen"),
    ClubOldModel("Leipzig"),
  ]);
  static LeagueModel ligue1 = LeagueModel("Ligue 1", [
    ClubOldModel("PSG"),
    ClubOldModel("Marseille"),
    ClubOldModel("Monaco"),
    ClubOldModel("Lyon"),
  ]);
  static LeagueModel eredivisie = LeagueModel("Eredivisie", [
    ClubOldModel("Ajax"),
    ClubOldModel("PSV"),
  ]);
}
