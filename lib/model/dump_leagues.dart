class League {
  final String title;
  final List<String> clubs;

  League(this.title, this.clubs);

  static List<League> leagues = [epl, laliga, seriea, bundesliga, eredivisie];

  static League epl = League("EPL", [
    "Manchester City",
    "Liverpool",
    "Chelsea",
    "Tottenham",
    "Arsenal",
    "Manchester United"
  ]);
  static League laliga = League("Laliga", [
    "Real Madrid",
    "Barcelona",
    "Atletico Madrid",
    "Sevilla",
  ]);
  static League seriea = League("Serie A", [
    "AC Milan",
    "Inter Milan",
    "Napoli",
    "Juventus",
    "Roma",
    "Atalanta",
  ]);
  static League bundesliga = League("Bundesliga", [
    "Bayern Munich",
    "Dortmund",
    "Bayer Leverkusen",
    "Leipzig",
  ]);
  static League ligue1 = League("Ligue 1", [
    "PSG",
    "Marseille",
    "Monaco",
    "Lyon",
  ]);
  static League eredivisie = League("Eredivisie", [
    "Ajax",
    "PSV",
  ]);
}
