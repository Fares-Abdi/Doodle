import 'package:flutter/material.dart';
import '../../services/game_service.dart';
import '../../services/websocket_service.dart';
import '../../utils/audio_mixin.dart';
import '../../utils/game_sounds.dart';
import 'game_room_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/game_session.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;
import 'test_keyboard_visibility_screen.dart';

class ScribbleLobbyScreen extends StatefulWidget {
  @override
  _ScribbleLobbyScreenState createState() => _ScribbleLobbyScreenState();
}

class _ScribbleLobbyScreenState extends State<ScribbleLobbyScreen> 
    with TickerProviderStateMixin, AudioMixin, WidgetsBindingObserver {
  final GameService _gameService = GameService();
  final TextEditingController _gameCodeController = TextEditingController();
  late String _playerId;
  late String _playerName;
  String _webSocketUrl = '';

  late AnimationController _floatingController;
  late AnimationController _logoController;
  late AnimationController _particleController;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePlayer();
    _loadWebSocketUrl();
    _initializeAudio();
    
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _particles = List.generate(20, (index) => Particle.random());
    _logoController.forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Only manage lobby music if we're actually on the lobby screen
      // Check if this screen is still in focus (simple check - if context is mounted)
      if (!context.mounted) return;
      
      final currentTrack = getAudioService().currentMusicTrack;
      
      // Don't override game music - the game screen will handle its own music
      if (currentTrack == GameSounds.gameMusic) {
        return;
      }
      
      // Only play/resume if we're not already playing the lobby music
      if (currentTrack == GameSounds.lobbyMusic && getAudioService().isMusicPlaying) {
        // Already playing, don't restart
        return;
      }
      
      // If no music is playing or it's a different track, play lobby music
      if (currentTrack != GameSounds.lobbyMusic) {
        playBackgroundMusic(GameSounds.lobbyMusic);
      } else {
        // Same track but paused, just resume
        resumeBackgroundMusic();
      }
    }
  }

  void _initializeAudio() async {
    // Only play lobby music if not already playing
    final currentTrack = getAudioService().currentMusicTrack;
    if (currentTrack != GameSounds.lobbyMusic) {
      await playBackgroundMusic(GameSounds.lobbyMusic);
    }
  }

  Future<void> _initializePlayer() async {
    final prefs = await SharedPreferences.getInstance();
    _playerId = prefs.getString('playerId') ?? const Uuid().v4();
    _playerName = prefs.getString('playerName') ?? 'Player ${_playerId.substring(0, 4)}';
    
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
    WidgetsBinding.instance.removeObserver(this);
    _floatingController.dispose();
    _logoController.dispose();
    _particleController.dispose();
    _gameCodeController.dispose();
    super.dispose();
  }

  Future<void> _createGame() async {
    await playButtonClick();
    
    final prefs = await SharedPreferences.getInstance();
    final savedAvatarColor = prefs.getString('player_avatar_$_playerId');
    
    final session = await GameSession.create(
      creatorId: _playerId,
      creatorName: _playerName,
      creatorAvatarColor: savedAvatarColor,
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

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: ParticlePainter(
            particles: _particles,
            progress: _particleController.value,
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Animated logo
          ScaleTransition(
            scale: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _logoController,
                curve: Curves.elasticOut,
              ),
            ),
            child: AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 12 * math.sin(_floatingController.value * math.pi)),
                  child: Image.asset(
                    'assets/images/Iresmini.png',
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.brush,
                        size: 60,
                        color: Colors.white,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          // Game title with shimmer effect
          FadeTransition(
            opacity: _logoController,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.8),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds);
              },
              child: const Text(
                'IRSEMNI',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(2, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 0),
          FadeTransition(
            opacity: _logoController,
            child: Text(
              'Draw • Guess • Win',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 2,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOut,
      )),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurpleAccent,
              Colors.purpleAccent.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurpleAccent.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Decorative circles
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "✨ FEATURED",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Create Your Own Room",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Start a game and invite your friends to join the fun!",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _createGame,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text(
                        "Create Room",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildAvailableGames() {
    return StreamBuilder<List<GameSession>>(
      stream: _gameService.getAvailableGames(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
          );
        }
        
        final games = snapshot.data!;
        
        if (games.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No rooms available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to create one!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    _gameService.refreshAvailableGames();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          color: Colors.deepPurple,
          onRefresh: () async {
            _gameService.refreshAvailableGames();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return _buildRoomCard(game, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildRoomCard(GameSession game, int index) {
    final roomColors = [
      [Colors.pink, Colors.pinkAccent],
      [Colors.blue, Colors.blueAccent],
      [Colors.green, Colors.greenAccent],
      [Colors.orange, Colors.orangeAccent],
      [Colors.teal, Colors.tealAccent],
    ];
    
    final colorSet = roomColors[index % roomColors.length];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorSet[0].withOpacity(0.1), colorSet[1].withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorSet[0].withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorSet[0].withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            await playButtonClick();
            
            final prefs = await SharedPreferences.getInstance();
            final savedAvatarColor = prefs.getString('player_avatar_$_playerId');
            
            await _gameService.joinGame(
              game.id,
              Player(
                id: _playerId,
                name: _playerName,
                photoURL: savedAvatarColor,
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Room icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colorSet,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorSet[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Room details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room ${index + 1}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${game.players.length}/3 players',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Open',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Join button
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorSet[0].withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: colorSet[0],
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableRoomsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Available Rooms",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          color: Colors.deepPurple,
          onPressed: () {
            _gameService.refreshAvailableGames();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Refreshing rooms...'),
                backgroundColor: Colors.deepPurple,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(milliseconds: 1000),
              ),
            );
          },
          tooltip: 'Refresh rooms',
        ),
      ],
    );
  }

  void _showServerSettingsDialog() {
    final TextEditingController urlController = TextEditingController(text: _webSocketUrl);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.settings, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Server Settings'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WebSocket Server URL:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                hintText: 'ws://192.168.200.163:8080',
                prefixIcon: const Icon(Icons.link, color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
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
                    SnackBar(
                      content: const Text('Server URL updated successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade700,
              Colors.purple.shade600,
            ],
          ),
        ),
        child: Stack(
          children: [
            _buildAnimatedBackground(),
            
            SafeArea(
              child: Column(
                children: [
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Header
                          _buildHeader(),
                          // Featured card
                          _buildFeaturedCard(),
                          
                          const SizedBox(height: 24),
                          // Available rooms section
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(32),
                              ),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: _buildAvailableRoomsHeader(),
                                ),
                                Container(
                                  constraints: BoxConstraints(
                                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                                  ),
                                  child: _buildAvailableGames(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Fixed App bar at top
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.science_rounded, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TestKeyboardVisibilityScreen(),
                          ),
                        );
                      },
                      tooltip: 'Test Keyboard Visibility',
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.settings_rounded, color: Colors.white),
                      onPressed: _showServerSettingsDialog,
                      tooltip: 'Server Settings',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Particle class for background animation
class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });

  factory Particle.random() {
    final random = math.Random();
    return Particle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: 2 + random.nextDouble() * 4,
      speed: 0.1 + random.nextDouble() * 0.3,
    );
  }
}

// Particle painter for animated background
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      final x = particle.x * size.width;
      final y = ((particle.y + (progress * particle.speed)) % 1.0) * size.height;
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}