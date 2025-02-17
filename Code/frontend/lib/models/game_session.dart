import 'dart:math';
import '../services/websocket_service.dart';
import 'package:firebase_database/firebase_database.dart';

enum GameState { waiting, starting, drawing, roundEnd, gameOver }

class Player {
  final String id;
  final String name;
  final String? photoURL;  // Add photoURL field
  int score;
  bool isDrawing;

  Player({
    required this.id,
    required this.name,
    this.photoURL,  // Add photoURL parameter
    this.score = 0,
    this.isDrawing = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'photoURL': photoURL,  // Add photoURL to JSON
    'score': score,
    'isDrawing': isDrawing,
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'],
    name: json['name'],
    photoURL: json['photoURL'] as String?,  // Add photoURL from JSON
    score: json['score'] ?? 0,
    isDrawing: json['isDrawing'] ?? false,
  );
}

class GameSession {
  final String id;
  List<Player> players;
  GameState state;
  String? currentWord;
  int roundTime;
  int currentRound;
  int maxRounds;
  DateTime? roundStartTime;
  List<String> playersGuessedCorrect;

  GameSession({
    required this.id,
    this.players = const [],
    this.state = GameState.waiting,
    this.currentWord,
    this.roundTime = 80,
    this.currentRound = 0,
    this.maxRounds = 0,  // Initialize to 0, will be set based on player count
    this.roundStartTime,
    this.playersGuessedCorrect = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'players': players.map((p) => p.toJson()).toList(),
    'state': state.toString(),
    'currentWord': currentWord,
    'roundTime': roundTime,
    'currentRound': currentRound,
    'maxRounds': maxRounds,
    'roundStartTime': roundStartTime?.millisecondsSinceEpoch,
    'playersGuessedCorrect': playersGuessedCorrect,
  };

  factory GameSession.fromJson(Map<String, dynamic> json) => GameSession(
    id: json['id'],
    players: (json['players'] as List)
        .map((p) => Player.fromJson(Map<String, dynamic>.from(p)))
        .toList(),
    state: GameState.values.firstWhere(
      (e) => e.toString() == json['state'],
      orElse: () => GameState.waiting,
    ),
    currentWord: json['currentWord'],
    roundTime: json['roundTime'] ?? 80,
    currentRound: json['currentRound'] ?? 0,
    maxRounds: json['maxRounds'] ?? 3,
    roundStartTime: json['roundStartTime'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['roundStartTime'])
        : null,
    playersGuessedCorrect: json['playersGuessedCorrect'] != null
        ? List<String>.from(json['playersGuessedCorrect'])
        : [],
  );

  static Future<GameSession> create({
    required String creatorId,
    required String creatorName,
  }) async {
    final session = GameSession(
      id: _generateId(),
      players: [
        Player(id: creatorId, name: creatorName, isDrawing: true),
      ],
      state: GameState.waiting,
    );
    
    WebSocketService().sendMessage('create_game', session.id, session.toJson());
    return session;
  }

  static String _generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }
}
