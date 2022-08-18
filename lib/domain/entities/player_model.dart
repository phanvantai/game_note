import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:game_note/core/ultils.dart';

class PlayerModel extends Equatable {
  final String fullname;
  final String level;
  final int? id;
  final Color? color = randomObject(Colors.accents);

  PlayerModel({required this.fullname, this.level = "Noob", this.id});

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

  @override
  List<Object?> get props => [fullname, level, id];

  static PlayerModel get virtualPlayer => PlayerModel(fullname: "Bot");
}
