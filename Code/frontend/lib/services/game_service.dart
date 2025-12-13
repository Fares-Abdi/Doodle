import 'dart:async';
import '../models/game_session.dart';
import 'websocket_service.dart';


class GameService {
  final _wsService = WebSocketService();

  Stream<GameSession> subscribeToGame(String gameId) {
    return _wsService.gameUpdates
        .where((data) => data['id'] == gameId)
        .map((data) => GameSession.fromJson(data));
  }

  Future<void> joinGame(String gameId, Player player) async {
    _wsService.sendMessage('join_game', gameId, {
      'player': player.toJson(),
    });
  }

  Future<void> leaveGame(String gameId) async {
    _wsService.sendMessage('leave_game', gameId, null);
  }

  Future<void> updatePlayer(String gameId, String playerId, String name, String photoURL) async {
    _wsService.sendMessage('update_player', gameId, {
      'playerId': playerId,
      'name': name,
      'photoURL': photoURL,
    });
  }

  Future<void> updateGame(String gameId, GameSession session) async {
    _wsService.sendMessage('update_game', gameId, session.toJson());
  }

  Stream<List<GameSession>> getAvailableGames() {
    _wsService.sendMessage('get_games', '', null);
    return _wsService.gamesList.map((games) {
      return games
          .map<GameSession>((game) => GameSession.fromJson(game))
          .where((game) => game.state == GameState.waiting)
          .toList();
    });
  }

  Future<void> refreshAvailableGames() async {
    _wsService.sendMessage('get_games', '', null);
  }

  Future<void> submitGuess(String gameId, String playerId, String guess) async {
    _wsService.sendMessage('submit_guess', gameId, {
      'playerId': playerId,
      'guess': guess,
    });
  }

  Future<void> startNewRound(String gameId) async {
    _wsService.sendMessage('start_new_round', gameId, null);
  }

  Future<void> endRound(String gameId) async {
    _wsService.sendMessage('end_round', gameId, null);
  }

  Future<void> handleCorrectGuess(String gameId, String playerId) async {
    _wsService.sendMessage('correct_guess', gameId, {
      'playerId': playerId,
    });
  }

  Future<void> startGame(String gameId) async {
    _wsService.sendMessage('start_game', gameId, null);
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
