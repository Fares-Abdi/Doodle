/// Sound effect constants for the game
class GameSounds {
  // Background Music
  static const String lobbyMusic = 'audio/music/lobby.mp3';
  static const String gameMusic = 'audio/music/game_music.mp3';
  static const String gameOverMusic = 'audio/music/game_over_music.mp3';
  static const String roundTransitionMusic = 'audio/music/next_round.m4a';

  // Game Events - Sound Effects
  static const String gameStart = 'audio/sfx/game_start.m4a';
  static const String foundWord = 'audio/sfx/found_word.m4a';
  static const String falseGuess = 'audio/sfx/false_guess.m4a';
  static const String roundEnd = 'audio/sfx/round_end.m4a';
  static const String playerJoined = 'audio/sfx/player_joined.m4a';
  static const String joinGame = 'audio/sfx/join_game.m4a';
  
  // Aliases for consistency
  static const String buttonClick = joinGame;
  static const String correctGuess = foundWord;
  static const String wrongGuess = falseGuess;
  static const String roundStart = gameStart;
  static const String gameOver = gameOverMusic;
  static const String notification = playerJoined;
}
