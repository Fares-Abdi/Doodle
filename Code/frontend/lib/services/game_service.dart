import 'dart:async';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import '../models/game_session.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class GameService {
  final _database = rtdb.FirebaseDatabase.instance.ref();

  final _words = [
    'cat', 'dog', 'house', 'tree', 'car', 'sun', 'moon', 'star',
    'book', 'phone', 'computer', 'pizza', 'flower', 'bird', 'fish',
    'airplane', 'boat', 'train', 'bicycle', 'mountain', 'beach',
    'rainbow', 'butterfly', 'guitar', 'elephant', 'penguin', 'robot',
    'castle', 'dragon', 'unicorn', 'wizard', 'pirate', 'rocket',
    'dinosaur', 'superhero', 'mermaid', 'ghost', 'alien', 'monster'
  ];

  Stream<GameSession> subscribeToGame(String gameId) {
    return _database
        .child('game_sessions')
        .child(gameId)
        .onValue
        .map((event) {
      if (event.snapshot.value == null) {
        throw Exception('Game session not found');
      }
      // Fix type casting
      final data = Map<String, dynamic>.from(event.snapshot.value as Map<Object?, Object?>);
      return GameSession.fromJson(data);
    });
  }

  Future<void> joinGame(String gameId, Player player) async {
    final gameRef = _database.child('game_sessions').child(gameId);
    
    await gameRef.runTransaction((Object? obj) {
      if (obj == null) return rtdb.Transaction.abort();
      
      final game = GameSession.fromJson(Map<String, dynamic>.from(obj as Map));
      
      // Check if game is full - only reject if MORE than 3 players try to join
      if (game.players.length > 3) {
        throw Exception('Game is full');
      }
      
      if (game.players.any((p) => p.id == player.id)) return rtdb.Transaction.success(obj);
      
      game.players.add(player);

      // If we now have exactly 3 players, update the maxRounds
      if (game.players.length == 3) {
        game.maxRounds = 3; // One round per player
      }
      
      return rtdb.Transaction.success(game.toJson());
    });
  }

  Future<void> submitGuess(String gameId, String playerId, String guess) async {
    final gameRef = _database.child('game_sessions').child(gameId);
    final snapshot = await gameRef.get();
    
    if (!snapshot.exists) return;
    
    final game = GameSession.fromJson(
      Map<String, dynamic>.from(snapshot.value as Map));
    
    if (game.currentWord?.toLowerCase() == guess.toLowerCase()) {
      // Update player score
      final playerIndex = game.players.indexWhere((p) => p.id == playerId);
      if (playerIndex != -1) {
        game.players[playerIndex].score += 100;
        await gameRef.child('players/$playerIndex/score')
            .set(game.players[playerIndex].score);
      }

      // End the current round and start the next one
      await endRound(gameId);
      await startNewRound(gameId);
    }
  }

  Future<void> startNewRound(String gameId) async {
    final gameRef = _database.child('game_sessions').child(gameId);
    final snapshot = await gameRef.get();
    if (!snapshot.exists) return;
    
    final game = GameSession.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
    
    // Check minimum players
    if (game.players.length < 2) return;

    // Set max rounds based on number of players
    if (game.maxRounds != game.players.length) {
      await gameRef.update({
        'maxRounds': game.players.length,
      });
    }

    // Check if we've reached the maximum rounds
    if (game.currentRound >= game.players.length) {
      await gameRef.update({
        'state': GameState.gameOver.toString(),
      });
      return;
    }

    // Select new random word
    final word = _words[Random().nextInt(_words.length)];
    
    // Update game state
    await gameRef.update({
      'currentWord': word,
      'state': GameState.drawing.toString(),
      'roundStartTime': rtdb.ServerValue.timestamp,  // Add rtdb prefix
      'playersGuessedCorrect': [],
    });
    
    // Remove the timer since we're handling it in the UI now
  }

  Future<void> endRound(String gameId) async {
    final gameRef = _database.child('game_sessions').child(gameId);
    final snapshot = await gameRef.get();
    if (!snapshot.exists) return;
    
    final game = GameSession.fromJson(
      Map<String, dynamic>.from(snapshot.value as Map));
    
    // Don't proceed if the game is already in roundEnd or gameOver state
    if (game.state == GameState.roundEnd || game.state == GameState.gameOver) {
      return;
    }

    // Increment round counter
    final nextRound = game.currentRound + 1;
    
    // Check if game should end
    if (nextRound >= game.players.length) {
      await gameRef.update({
        'state': GameState.gameOver.toString(),
        'currentRound': nextRound,
      });
      return;
    }
    
    // Rotate to next drawer
    final currentDrawerIndex = game.players.indexWhere((p) => p.isDrawing);
    final nextDrawerIndex = (currentDrawerIndex + 1) % game.players.length;
    
    game.players[currentDrawerIndex].isDrawing = false;
    game.players[nextDrawerIndex].isDrawing = true;

    // Update game state to roundEnd instead of waiting
    await gameRef.update({
      'state': GameState.roundEnd.toString(),
      'currentRound': nextRound,
      'players': game.players.map((p) => p.toJson()).toList(),
      'currentWord': null,
      'drawing_data': null,
      'playersGuessedCorrect': [],
      'roundStartTime': null,
    });

    // Start new round after a short delay
    Timer(const Duration(seconds: 3), () async {
      // First update state to drawing
      await gameRef.update({
        'state': GameState.drawing.toString(),
      });
      // Then start the new round
      await startNewRound(gameId);
    });
  }

  Future<void> handleCorrectGuess(String gameId, String playerId) async {
    final gameRef = _database.child('game_sessions').child(gameId);
    final snapshot = await gameRef.get();
    if (!snapshot.exists) return;

    final game = GameSession.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
    
    // Update scores
    final guessingPlayer = game.players.firstWhere((p) => p.id == playerId);
    final drawingPlayer = game.players.firstWhere((p) => p.isDrawing);
    
    guessingPlayer.score += 5;  // Points for guessing
    drawingPlayer.score += 2;   // Points for drawing

    // Add player to correct guesses list
    List<String> correctGuesses = [];
    final correctGuessesSnapshot = await gameRef.child('playersGuessedCorrect').get();
    if (correctGuessesSnapshot.exists && correctGuessesSnapshot.value != null) {
      correctGuesses = List<String>.from(correctGuessesSnapshot.value as List);
    }
    correctGuesses.add(playerId);

    // Update player scores and correct guesses
    await gameRef.update({
      'players': game.players.map((p) => p.toJson()).toList(),
      'playersGuessedCorrect': correctGuesses,
    });

    // Check if all non-drawing players have guessed correctly
    final nonDrawingPlayers = game.players.where((p) => !p.isDrawing).length;
    if (correctGuesses.length >= nonDrawingPlayers) {
      // End round if everyone has guessed
      await endRound(gameId);
    }
  }

  Future<void> startGame(String gameId) async {
    final gameRef = _database.child('game_sessions').child(gameId);
    final snapshot = await gameRef.get();
    
    if (!snapshot.exists) return;
    
    final game = GameSession.fromJson(
      Map<String, dynamic>.from(snapshot.value as Map));
    
    // Only start if we have 2 or 3 players
    if (game.players.length >= 2 && game.players.length <= 3) {
      // Make first player the drawer
      for (var player in game.players) {
        player.isDrawing = false;
      }
      game.players.first.isDrawing = true;
      
      await gameRef.update({
        'state': GameState.drawing.toString(),
        'players': game.players.map((p) => p.toJson()).toList(),
      });
      
      // Start the first round
      await startNewRound(gameId);
    }
  }

  Stream<List<GameSession>> getAvailableGames() {
    return _database
        .child('game_sessions')
        .onValue
        .map((event) {
      final games = <GameSession>[];
      if (event.snapshot.value != null) {
        final gamesMap = Map<String, dynamic>.from(event.snapshot.value as Map);
        gamesMap.forEach((key, value) {
          final gameData = Map<String, dynamic>.from(value);
          gameData['id'] = key;
          final game = GameSession.fromJson(gameData);
          // Only show games that are in waiting state and have less than 3 players
          // Changed from "length < 3" to "length <= 3" to allow the third player to see and join
          if (game.state == GameState.waiting && game.players.length <= 3) {
            games.add(game);
          }
        });
      }
      return games;
    });
  }

  Future<Player> createPlayer(String userId, String userName) async {
    // Fetch user data from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    final userData = userDoc.data();
    
    return Player(
      id: userId,
      name: userName,
      photoURL: userData?['photoURL'] as String?,
      score: 0,
      isDrawing: false,
    );
  }
}
