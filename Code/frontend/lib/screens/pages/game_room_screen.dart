import 'package:flutter/material.dart';
import '../../widgets/advanced_drawing_canvas.dart';
import '../../widgets/game_chat.dart';
import '../../models/game_session.dart';
import '../../services/game_service.dart';
import 'package:collection/collection.dart';

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
  
  // Add this map to track which players we've seen
  final Set<String> _animatedPlayers = {};

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

  Widget _buildPlayerAvatar(Player player, bool isNewPlayer) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut, // Changed from elasticOut to prevent overshooting
      tween: Tween<double>(
        begin: isNewPlayer ? 0.0 : 1.0,
        end: 1.0,
      ),
      onEnd: () {
        _animatedPlayers.add(player.id);
      },
      builder: (context, value, child) {
        return Transform.scale(
          scale: value.clamp(0.0, 1.0), // Clamp scale value
          child: Opacity(
            opacity: value.clamp(0.0, 1.0), // Clamp opacity value
            child: Column(
              children: [
                CircleAvatar(
                  radius: player.id == widget.userId ? 40 : 30,
                  backgroundImage: player.photoURL != null ? NetworkImage(player.photoURL!) : null,
                  backgroundColor: Colors.white,
                  child: player.photoURL == null ? Text(
                    player.name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: player.id == widget.userId ? 24 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ) : null,
                ),
                const SizedBox(height: 8),
                Text(
                  player.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameContent(GameSession session) {
    final currentPlayer = session.players.firstWhere((p) => p.id == widget.userId);

    // Show waiting screen
    if (session.state == GameState.waiting) {
      return Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color.fromARGB(255, 39, 28, 85), const Color.fromARGB(255, 96, 30, 144)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar for waiting room
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        'Waiting Room',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${session.players.length} players are in the waiting room',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white
                          ),
                        ),
                        const SizedBox(height: 40),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 24,  // Increased spacing
                          runSpacing: 24,  // Increased spacing
                          children: session.players.map((player) {
                            final isNewPlayer = !_animatedPlayers.contains(player.id);
                            return _buildPlayerAvatar(player, isNewPlayer);
                          }).toList(),
                        ),
                        const SizedBox(height: 48),
                        ElevatedButton(
                          onPressed: session.players.length >= 2 
                            ? () => _gameService.startGame(widget.gameId)
                            : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.deepPurple,
                            disabledBackgroundColor: Colors.white.withOpacity(0.3),
                            disabledForegroundColor: Colors.white.withOpacity(0.5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)
                            ),
                          ),
                          child: Text(
                            session.players.length >= 2 ? 'START GAME' : 'WAITING FOR PLAYERS',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Show round transition screen
    if (session.state == GameState.roundEnd) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color.fromARGB(255, 39, 28, 85), const Color.fromARGB(255, 96, 30, 144)],
          ),
        ),
        child: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Round Complete!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Next round starting soon...',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: value,
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                          strokeWidth: 8,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: session.players.map((player) {
                          final isNextDrawer = session.players.indexOf(player) == 
                              (session.players.indexWhere((p) => p.isDrawing) + 1) % session.players.length;
                          return Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: isNextDrawer ? 35 : 30,
                                    backgroundImage: player.photoURL != null ? NetworkImage(player.photoURL!) : null,
                                    backgroundColor: isNextDrawer ? Colors.white : Colors.white60,
                                    child: player.photoURL == null ? Text(
                                      player.name[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: isNextDrawer ? 24 : 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ) : null,
                                  ),
                                  if (isNextDrawer)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.brush,
                                          color: Colors.deepPurple,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                player.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isNextDrawer ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              Text(
                                '${player.score} pts',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

 // Main game content
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade50, Colors.purple.shade50],
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Round ${session.currentRound + 1}/${session.maxRounds}'),
                    if (session.roundStartTime != null)
                      StreamBuilder(
                        stream: Stream.periodic(const Duration(seconds: 1)),
                        builder: (context, snapshot) {
                          final remaining = session.roundTime -
                              DateTime.now()
                                  .difference(session.roundStartTime!)
                                  .inSeconds;
                          
                          // End round when timer reaches zero
                          if (remaining <= 0 && session.state == GameState.drawing) {
                            _gameService.endRound(widget.gameId);
                          }

                          return Text(
                            'Time: ${remaining > 0 ? remaining : 0}s',
                            style: TextStyle(
                              color: remaining < 10 ? Colors.red : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    Text('Score: ${currentPlayer.score}'),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: AdvancedDrawingCanvas(
                            userId: widget.userId,
                            gameSession: session,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: _isChatVisible ? 16 : 16,  // Update these valueschat is visible
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _toggleChat,
            backgroundColor: Colors.deepPurple,
            child: Icon(
              _isChatVisible ? Icons.chat_bubble : Icons.chat_bubble_outline,
              color: Colors.white,
            ),
          ),
        ),
        Positioned(
          right: 0,  // Keep the chat panel on the right
          top: 0,
          bottom: 0,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(_chatPanelAnimation),
            child: Container(
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.deepPurple.shade100,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Players',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...session.players.map((player) => _buildPlayerTile(player)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GameChat(
                      gameSession: session,
                      userId: widget.userId,
                      userName: widget.userName,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildPlayerTile(Player player) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: player.isDrawing ? Colors.deepPurple.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: player.isDrawing ? [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 1,
          )
        ] : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (player.isDrawing)
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut, // Changed from default to prevent overshooting
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value.clamp(0.0, 1.0), // Clamp opacity value
                      child: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.brush, color: Colors.deepPurple, size: 16),
                      ),
                    );
                  },
                ),
              CircleAvatar(
                radius: 16,
                backgroundImage: player.photoURL != null ? NetworkImage(player.photoURL!) : null,
                backgroundColor: Colors.deepPurple.shade50,
                child: player.photoURL == null 
                    ? Text(
                        player.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ) 
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                player.name,
                style: TextStyle(
                  color: player.isDrawing ? Colors.deepPurple : Colors.black87,
                  fontWeight: player.isDrawing ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          TweenAnimationBuilder<int>(
            duration: const Duration(milliseconds: 500),
            tween: IntTween(begin: 0, end: player.score),
            builder: (context, value, child) {
              return Text(
                value.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              );
            },
          ),
        ],
      ),
    );
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
          
          // Now we can safely use session for the AppBar condition
          return Scaffold(
            body: session.state == GameState.gameOver
              ? Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.deepPurple.shade900, Colors.deepPurple.shade500],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        'Srible Game',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                        const Text(
                          'Game Over!',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Second Place
                                if (session.players.length > 1) _buildPodiumSpot(
                                  session.players.sorted((a, b) => b.score.compareTo(a.score))[1],
                                  160,
                                  Colors.grey.shade300,
                                  '2nd',
                                ),
                                const SizedBox(width: 12),
                                // First Place
                                _buildPodiumSpot(
                                  session.players.sorted((a, b) => b.score.compareTo(a.score))[0],
                                  200,
                                  Colors.amber,
                                  '1st',
                                ),
                                const SizedBox(width: 12),
                                // Third Place
                                if (session.players.length > 2) _buildPodiumSpot(
                                  session.players.sorted((a, b) => b.score.compareTo(a.score))[2],
                                  120,
                                  Colors.brown.shade300,
                                  '3rd',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        // Other players
                        if (session.players.length > 3) ...[
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: session.players
                                  .sorted((a, b) => b.score.compareTo(a.score))
                                  .skip(3)
                                  .map((player) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${session.players.sorted((a, b) => b.score.compareTo(a.score)).indexOf(player) + 1}. ',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          '${player.name}: ${player.score}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                                  .toList(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Back to Lobby',
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildGameContent(session),
          );
        },
      ),
    );
  }

  Widget _buildPodiumSpot(Player player, double height, Color color, String place) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: place == '1st' ? 40 : 30,
          backgroundImage: player.photoURL != null ? NetworkImage(player.photoURL!) : null,
          backgroundColor: Colors.white,
          child: player.photoURL == null
              ? Text(
                  player.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: place == '1st' ? 24 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          player.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: place == '1st' ? 18 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${player.score} pts',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              place,
              style: TextStyle(
                color: place == '1st' ? Colors.black : Colors.black87,
                fontSize: place == '1st' ? 24 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
