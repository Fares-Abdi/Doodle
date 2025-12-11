import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../services/game_service.dart';
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

class _GameRoomScreenState extends State<GameRoomScreen> with SingleTickerProviderStateMixin {
  final GameService _gameService = GameService();
  late Stream<GameSession> _gameStream;
  late AnimationController _chatPanelController;
  late Animation<double> _chatPanelAnimation;
  bool _isChatVisible = false;

  @override
  void initState() {
    super.initState();
    _gameStream = _gameService.subscribeToGame(widget.gameId);
    
    _chatPanelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _chatPanelAnimation = CurvedAnimation(
      parent: _chatPanelController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    // Send leave_game message to server when leaving the room
    _gameService.leaveGame(widget.gameId);
    _chatPanelController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        onStartGame: () => _gameService.startGame(widget.gameId),
        onBack: () => Navigator.of(context).pop(),
      );
    }

    // Show round transition screen
    if (session.state == GameState.roundEnd) {
      return RoundTransition(session: session);
    }

    // Main game screen
    return Scaffold(
      body: Stack(
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
          
          // Top-right close button (if chat is visible)
          if (_isChatVisible)
            Positioned(
              right: 16,
              top: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _toggleChat,
                  tooltip: 'Close chat',
                ),
              ),
            ),
          
          // Bottom-left chat toggle button (doesn't get covered)
          Positioned(
            left: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: _toggleChat,
              backgroundColor: Colors.deepPurple,
              icon: Icon(
                _isChatVisible ? Icons.chat : Icons.chat_bubble_outline,
                color: Colors.white,
              ),
              label: Text(
                _isChatVisible ? 'Hide' : 'Chat',
                style: const TextStyle(color: Colors.white),
              ),
              tooltip: _isChatVisible ? 'Hide chat' : 'Show chat',
            ),
          ),
        ],
      ),
    );
  }
}