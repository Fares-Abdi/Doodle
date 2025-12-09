import 'package:flutter/material.dart';
import '../../services/game_service.dart';
import '../../services/websocket_service.dart';
import 'game_room_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/game_session.dart';
import 'package:uuid/uuid.dart';

class ScribbleLobbyScreen extends StatefulWidget {
  @override
  _ScribbleLobbyScreenState createState() => _ScribbleLobbyScreenState();
}

class _ScribbleLobbyScreenState extends State<ScribbleLobbyScreen> with SingleTickerProviderStateMixin {
  final GameService _gameService = GameService();
  final TextEditingController _gameCodeController = TextEditingController();
  late String _playerId;
  late String _playerName;
  bool isPrivate = true;
  String _webSocketUrl = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _loadWebSocketUrl();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _initializePlayer() async {
    final prefs = await SharedPreferences.getInstance();
    _playerId = prefs.getString('playerId') ?? const Uuid().v4();
    _playerName = prefs.getString('playerName') ?? 'Player ${_playerId.substring(0, 4)}';
    
    // Save to preferences if new
    await prefs.setString('playerId', _playerId);
    await prefs.setString('playerName', _playerName);
    
    setState(() {});
  }

  Future<void> _loadWebSocketUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _webSocketUrl = prefs.getString('webSocketServerUrl') ?? 'ws://192.168.200.163:8080';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _gameCodeController.dispose();
    super.dispose();
  }

  Future<void> _createGame() async {
    // Create game logic
    final session = await GameSession.create(
      creatorId: _playerId,
      creatorName: _playerName,
    );
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameRoomScreen(
            gameId: session.id,
            userId: _playerId,
            userName: _playerName,
          ),
        ),
      );
    }
  }

  Future<void> _joinGame() async {
    final gameId = _gameCodeController.text.trim();
    if (gameId.isEmpty) return;
    // Join game logic
    await _gameService.joinGame(
      gameId,
      Player(
        id: _playerId,
        name: _playerName,
      ),
    );
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameRoomScreen(
            gameId: gameId,
            userId: _playerId,
            userName: _playerName,
          ),
        ),
      );
    }
  }

  Widget _buildAvailableGames() {
    return StreamBuilder<List<GameSession>>(
      stream: _gameService.getAvailableGames(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final games = snapshot.data!;
        if (games.isEmpty) {
          return const Center(
            child: Text('No games available.\nCreate a new one!'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  // Placeholder for a room icon or avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.pink.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.grid_view, color: Colors.pink.shade400),
                  ),
                  const SizedBox(width: 16),
                  // Room details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room ${index + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${game.players.length}/3 players',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  // Join button
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, color: Colors.purple),
                    onPressed: () async {
                      await _gameService.joinGame(
                        game.id,
                        Player(
                          id: _playerId,
                          name: _playerName,
                        ),
                      );
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameRoomScreen(
                              gameId: game.id,
                              userId: _playerId,
                              userName: _playerName,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildToggleSwitch() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildToggleOption(
                title: "Public",
                isSelected: !isPrivate,
                onTap: () {
                  setState(() {
                    isPrivate = false;
                    _animationController.forward(from: 0.0);
                  });
                },
              ),
              const SizedBox(width: 40), // Increased spacing between toggles
              _buildToggleOption(
                title: "Private",
                isSelected: isPrivate,
                onTap: () {
                  setState(() {
                    isPrivate = true;
                    _animationController.forward(from: 0.0);
                  });
                },
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: _buildPublicContent(),
          secondChild: _buildPrivateContent(),
          crossFadeState: isPrivate ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }

  Widget _buildToggleOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18, // Increased font size
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.deepPurple : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isSelected ? Colors.deepPurple : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            children: [
              TextField(
                controller: _gameCodeController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[200],
                  hintText: "Enter the code ...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20), // Increased spacing
              ElevatedButton(
                onPressed: _joinGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  minimumSize: const Size(200, 50), // Set minimum size
                ),
                child: const Text(
                  "Join",
                  style: TextStyle(fontSize: 16), // Increased font size
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPublicContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: const Text(
            "Available Rooms",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
      ),
    );
  }

  void _showServerSettingsDialog() {
    final TextEditingController urlController = TextEditingController(text: _webSocketUrl);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('WebSocket Server URL:'),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                hintText: 'ws://192.168.200.163:8080',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty) {
                await WebSocketService().reconnectWithNewUrl(newUrl);
                _webSocketUrl = newUrl;
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Server URL updated successfully')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade900,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showServerSettingsDialog,
            tooltip: 'Server Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Featured Card for create game
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.deepPurpleAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "FEATURED",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Take part in challenges with friends or other players",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton(
                          onPressed: _createGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text("Create a room"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Expanded container with join game inputs and available games list
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildToggleSwitch(),
                      const SizedBox(height: 20), // Added spacing
                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: !isPrivate ? 1.0 : 0.0,
                          child: !isPrivate ? _buildAvailableGames() : const SizedBox(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
