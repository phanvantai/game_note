import 'package:game_note/domain/entities/player_model.dart';

abstract class PlayerLocalDataSource {
  Future<PlayerModel> getPlayer(int playerId);
  Future<List<PlayerModel>> getPlayers();
}

class PlayerLocalDataSourceImpl implements PlayerLocalDataSource {
  @override
  Future<PlayerModel> getPlayer(int playerId) async {
    // TODO: implement getPlayer
    throw UnimplementedError();
  }

  @override
  Future<List<PlayerModel>> getPlayers() async {
    // TODO: implement getPlayers
    throw UnimplementedError();
  }
}
