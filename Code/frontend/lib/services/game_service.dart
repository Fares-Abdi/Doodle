import 'dart:async';
import '../models/game_session.dart';
import 'websocket_service.dart';


class GameService {
  final wsService = WebSocketService();

  Stream<GameSession> subscribeToGame(String gameId) {
    return wsService.gameUpdates
        .where((data) => data['id'] == gameId)
        .map((data) => GameSession.fromJson(data));
  }

  Future<void> joinGame(String gameId, Player player) async {
    wsService.sendMessage('join_game', gameId, {
      'player': player.toJson(),
    });
  }

  Future<void> leaveGame(String gameId) async {
    wsService.sendMessage('leave_game', gameId, null);
  }

  Future<void> destroyRoom(String gameId) async {
    wsService.sendMessage('destroy_room', gameId, null);
  }

  Future<void> updatePlayer(String gameId, String playerId, String name, String photoURL) async {
    wsService.sendMessage('update_player', gameId, {
      'playerId': playerId,
      'name': name,
      'photoURL': photoURL,
    });
  }

  Future<void> updateGame(String gameId, GameSession session) async {
    wsService.sendMessage('update_game', gameId, session.toJson());
  }

  Stream<List<GameSession>> getAvailableGames() {
    wsService.sendMessage('get_games', '', null);
    return wsService.gamesList.map((games) {
      return games
          .map<GameSession>((game) => GameSession.fromJson(game))
          .where((game) => game.state == GameState.waiting)
          .toList();
    });
  }

  Future<void> refreshAvailableGames() async {
    wsService.sendMessage('get_games', '', null);
  }

  Future<void> submitGuess(String gameId, String playerId, String guess) async {
    wsService.sendMessage('submit_guess', gameId, {
      'playerId': playerId,
      'guess': guess,
    });
  }

  Future<void> startNewRound(String gameId) async {
    wsService.sendMessage('start_new_round', gameId, null);
  }

  Future<void> endRound(String gameId) async {
    wsService.sendMessage('end_round', gameId, null);
  }

  Future<void> handleCorrectGuess(String gameId, String playerId) async {
    wsService.sendMessage('correct_guess', gameId, {
      'playerId': playerId,
    });
  }

  Future<void> startGame(String gameId) async {
    wsService.sendMessage('start_game', gameId, null);
  }

  Future<Player> createPlayer(String userId, String userName) async {
    return Player(
      id: userId,
      name: userName,
      score: 0,
      isDrawing: false,
    );
  }
}
