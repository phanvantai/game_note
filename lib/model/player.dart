class Player {
  final String fullname;
  final String level;
  int? id;

  Player({required this.fullname, this.level = "Noob", this.id});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullname': fullname,
      'level': level,
    };
  }

  @override
  String toString() {
    return 'Player{id: $id, fullname: $fullname, level: $level}';
  }
}
