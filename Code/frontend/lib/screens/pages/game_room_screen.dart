import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../services/game_service.dart';
import '../../utils/audio_mixin.dart';
import '../../utils/game_sounds.dart';
import '../../widgets/waiting_room.dart';
import '../../widgets/round_transition.dart';
import '../../widgets/game_over_screen.dart';
import '../../widgets/game_board.dart';
import '../../widgets/chat_panel.dart';
import '../../widgets/player_tile.dart';

class GameRoomScreen extends StatefulWidget {
  final String gameId;
  final String userId;
  final String userName;

  const GameRoomScreen({
    Key? key,
    required this.gameId,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<GameRoomScreen> createState() => _GameRoomScreenState();
}

class _GameRoomScreenState extends State<GameRoomScreen> with SingleTickerProviderStateMixin, AudioMixin {
  final GameService _gameService = GameService();
  late Stream<GameSession> _gameStream;
  late AnimationController _chatPanelController;
  late Animation<double> _chatPanelAnimation;
  bool _isChatVisible = false;

  @override
  void initState() {
    super.initState();
    _gameStream = _gameService.subscribeToGame(widget.gameId);
    _listenToGameState();
    
    _chatPanelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _chatPanelAnimation = CurvedAnimation(
      parent: _chatPanelController,
      curve: Curves.easeInOut,
    );
  }

  void _listenToGameState() {
    _gameStream.listen((gameSession) {
      // When game state changes to drawing, ensure game music is playing
      if (gameSession.state == GameState.drawing) {
        // Only stop music if it's not already the game music
        if (getAudioService().currentMusicTrack != GameSounds.gameMusic) {
          stopBackgroundMusic();
          Future.delayed(const Duration(milliseconds: 300), () {
            playBackgroundMusic(GameSounds.gameMusic);
          });
        }
      }
      
      // When round ends, return to waiting room - music should switch back to lobby
      if (gameSession.state == GameState.roundEnd) {
        // Music will be handled by waiting room when it's shown
        // But we should make sure to stop game music
        stopBackgroundMusic();
      }
      
      // When game is over, ensure lobby music will play when we return
      if (gameSession.state == GameState.gameOver) {
        // Game over screen will handle the music
        // No action needed here
      }
    });
  }

  @override
  void dispose() {
    // Send leave_game message to server when leaving the room
    _gameService.leaveGame(widget.gameId);
    _chatPanelController.dispose();
    // Ensure lobby music plays when returning to lobby
    playBackgroundMusic(GameSounds.lobbyMusic);
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isChatVisible = !_isChatVisible;
      if (_isChatVisible) {
        _chatPanelController.forward();
      } else {
        _chatPanelController.reverse();
      }
    });
  }

  Future<bool> _onBackPressed() async {
    _showExitConfirmation();
    return false; // Prevent default back button behavior
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit Game?'),
          content: const Text('Are you sure you want to leave the game? Your progress will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _gameService.leaveGame(widget.gameId);
                Navigator.of(context).pop();
              },
              child: const Text('Exit', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        body: StreamBuilder<GameSession>(
          stream: _gameStream,
          builder: (context, snapshot) {
            // Show loading indicator while waiting for data
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final session = snapshot.data!;
            
            return Scaffold(
              body: _buildMainContent(session),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(GameSession session) {
    // Show game over screen
    if (session.state == GameState.gameOver) {
      return GameOverScreen(
        session: session,
        onBackToLobby: () => Navigator.of(context).pop(),
      );
    }
    
    // Show waiting screen
    if (session.state == GameState.waiting) {
      return WaitingRoom(
        session: session,
        userId: widget.userId,
        onStartGame: () {
          // Stop lobby music immediately when game starts
          stopBackgroundMusic();
          _gameService.startGame(widget.gameId);
        },
        onBack: () => Navigator.of(context).pop(),
      );
    }

    // Show round transition screen
    if (session.state == GameState.roundEnd) {
      return RoundTransition(session: session);
    }

    // Main game screen
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade700,
      body: SafeArea(
        child: Stack(
          children: [
            // Main game board takes full space
            GameBoard(
              session: session,
              userId: widget.userId,
              onEndRound: () => _gameService.endRound(widget.gameId),
            ),
            
            // Chat panel on the right side (doesn't cover controls)
            ChatPanel(
              visible: _isChatVisible,
              animation: _chatPanelAnimation,
              session: session,
              userId: widget.userId,
              userName: widget.userName,
              buildPlayerTile: (player) => PlayerTile(
                player: player,
                isHighlighted: player.id == widget.userId,
              ),
            ),
            
            // Bottom-left chat toggle button (doesn't get covered)
            Positioned(
              left: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: _toggleChat,
                backgroundColor: Colors.deepPurple,
                tooltip: _isChatVisible ? 'Hide chat' : 'Show chat',
                child: Icon(
                  _isChatVisible ? Icons.chat : Icons.chat_bubble_outline,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}