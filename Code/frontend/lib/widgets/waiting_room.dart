import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:ui' show ImageFilter;
import '../models/game_session.dart';
import '../services/game_service.dart';
import '../utils/audio_mixin.dart';
import '../utils/game_sounds.dart';
import 'player_profile_editor.dart';

class WaitingRoom extends StatefulWidget {
  final GameSession session;
  final String userId;
  final VoidCallback onStartGame;
  final VoidCallback onBack;

  const WaitingRoom({
    Key? key,
    required this.session,
    required this.userId,
    required this.onStartGame,
    required this.onBack,
  }) : super(key: key);

  @override
  State<WaitingRoom> createState() => _WaitingRoomState();
}

class _WaitingRoomState extends State<WaitingRoom> with TickerProviderStateMixin, AudioMixin {
  late Set<String> _leavingPlayers;
  late List<Player> _previousPlayers;
  final GameService _gameService = GameService();
  bool _roomDestroyed = false;
  late TextEditingController _nameController;
  late AnimationController _animationController;
  late AnimationController _buttonGlowController;
  late AnimationController _playerJoinController;
  
  late Map<String, Player> _displayPlayers;
  String? _lastJoinedPlayerId;
  String? _playerLeftMessage;

  @override
  void initState() {
    super.initState();
    _leavingPlayers = {};
    _previousPlayers = List.from(widget.session.players);
    _displayPlayers = {for (var p in widget.session.players) p.id: p};
    final currentPlayer = widget.session.players.firstWhere(
      (p) => p.id == widget.userId,
      orElse: () => Player(id: widget.userId, name: 'Player'),
    );
    _nameController = TextEditingController(text: currentPlayer.name);
    _loadSavedProfile();
    
    // Initialize animated gradient controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    
    // Initialize button glow controller
    _buttonGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    // Initialize player join animation controller
    _playerJoinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    // Ensure lobby music continues in waiting room
    _ensureLobbyMusicPlaying();
  }

  void _ensureLobbyMusicPlaying() async {
    // Only play lobby music if music is enabled
    final audioService = getAudioService();
    
    // Don't play if music is disabled
    if (!audioService.isMusicEnabled) {
      return;
    }
    
    // If game music is paused but still set, don't override it - let the parent handle resume
    if (audioService.currentMusicTrack == GameSounds.gameMusic) {
      return;
    }
    
    // Only play lobby music if truly no music is set
    if (audioService.currentMusicTrack != GameSounds.lobbyMusic || !audioService.isMusicPlaying) {
      await playBackgroundMusic(GameSounds.lobbyMusic);
    }
  }

  Future<void> _loadSavedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('player_name_${widget.userId}');
    
    if (savedName != null) {
      _nameController.text = savedName;
    }
  }

  Future<void> _saveProfileLocally(String name, String avatarColor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('player_name_${widget.userId}', name);
    await prefs.setString('player_avatar_${widget.userId}', avatarColor);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animationController.dispose();
    _buttonGlowController.dispose();
    _playerJoinController.dispose();
    super.dispose();
  }

  bool _haveAllPlayersExited() {
    return widget.session.players.isEmpty;
  }

  @override
  void didUpdateWidget(WaitingRoom oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    _displayPlayers = {for (var p in widget.session.players) p.id: p};
    
    final currentPlayerIds = widget.session.players.map((p) => p.id).toSet();
    final previousPlayerIds = _previousPlayers.map((p) => p.id).toSet();
    
    final leftPlayerIds = previousPlayerIds.difference(currentPlayerIds);
    final joinedPlayerIds = currentPlayerIds.difference(previousPlayerIds);
    
    if (leftPlayerIds.isNotEmpty) {
      setState(() {
        _leavingPlayers.addAll(leftPlayerIds);
        final count = leftPlayerIds.length;
        _playerLeftMessage = '$count player${count > 1 ? 's' : ''} left the room';
      });
      
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() {
            _leavingPlayers.removeAll(leftPlayerIds);
            _playerLeftMessage = null;
          });
        }
      });
    }
    
    if (joinedPlayerIds.isNotEmpty) {
      if (_previousPlayers.isNotEmpty) {
        // Play player joined sound
        playPlayerJoined();
        
        setState(() {
          _lastJoinedPlayerId = joinedPlayerIds.first;
        });
        _playerJoinController.forward(from: 0);
        
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() {
              _lastJoinedPlayerId = null;
            });
          }
        });
      }
    }
    
    if (_haveAllPlayersExited() && !_roomDestroyed) {
      _roomDestroyed = true;
      _handleRoomDestruction();
    }
    
    _previousPlayers = List.from(widget.session.players);
  }

  void _handleRoomDestruction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All players left. Room has been destroyed.'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.deepPurple,
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onBack();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        body: Stack(
          children: [
            _buildAnimatedGradientBackground(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: _showExitConfirmation,
                        ),
                        const Expanded(
                          child: Text(
                            'Waiting Room',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.person_outline, color: Colors.white),
                          onPressed: _showProfileEditor,
                          tooltip: 'Edit Profile',
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildPlayersGrid(),
                    ),
                  ),



                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: _buildRoomSettings(),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: AnimatedBuilder(
                      animation: _buttonGlowController,
                      builder: (context, child) {
                        final canStart = widget.session.players.length >= 2;
                        final glowIntensity = canStart 
                            ? 0.2 + (_buttonGlowController.value * 0.3) 
                            : 0.0;
                        
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: canStart ? [
                              BoxShadow(
                                color: const Color(0xFF9D4EDD).withOpacity(glowIntensity),
                                blurRadius: 12 + (glowIntensity * 8),
                                spreadRadius: 1 + (glowIntensity * 1),
                              ),
                              BoxShadow(
                                color: const Color(0xFFC77DFF).withOpacity(glowIntensity * 0.3),
                                blurRadius: 16 + (glowIntensity * 12),
                                spreadRadius: 2 + (glowIntensity * 2),
                              ),
                            ] : [],
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: canStart ? widget.onStartGame : null,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: EdgeInsets.zero,
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                disabledBackgroundColor: Colors.transparent,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: canStart
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF7B2CBF),
                                            Color(0xFF9D4EDD),
                                          ],
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Colors.grey.withOpacity(0.2),
                                            Colors.grey.withOpacity(0.3),
                                          ],
                                        ),
                                  borderRadius: const BorderRadius.all(Radius.circular(30)),
                                ),
                                child: Center(
                                  child: Text(
                                    canStart ? "START GAME" : "WAITING FOR PLAYERS",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: canStart ? Colors.white : Colors.white54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedGradientBackground() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animValue = _animationController.value;
        final sineValue = (sin(animValue * 6.28) + 1) / 2;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  const Color(0xFF1A0B2E),
                  const Color(0xFF2D1B4E),
                  sineValue,
                )!,
                Color.lerp(
                  const Color(0xFF2D1B4E),
                  const Color(0xFF4A2C6D),
                  sineValue,
                )!,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayersGrid() {
    final maxPlayers = widget.session.maxPlayers;
    final emptySlots = maxPlayers - _displayPlayers.length;
    
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      children: [
        ..._displayPlayers.values.map((player) {
          final isLeavingPlayer = _leavingPlayers.contains(player.id);
          final isJoiningPlayer = _lastJoinedPlayerId == player.id;
          
          return AnimatedBuilder(
            animation: _playerJoinController,
            builder: (context, child) {
              final scale = isJoiningPlayer 
                  ? 0.5 + (_playerJoinController.value * 0.5)
                  : 1.0;
              final opacity = isLeavingPlayer 
                  ? 0.3 
                  : (isJoiningPlayer ? _playerJoinController.value : 1.0);
              
              return Transform.scale(
                scale: scale,
                child: AnimatedOpacity(
                  opacity: opacity,
                  duration: const Duration(milliseconds: 300),
                  child: _buildPlayerCard(
                    name: player.name,
                    avatarColor: player.photoURL ?? 'blue',
                    isCurrentUser: player.id == widget.userId,
                    isLeaving: isLeavingPlayer,
                    player: player,
                  ),
                ),
              );
            },
          );
        }),
        ...List.generate(
          emptySlots,
          (index) => const _EmptySlot(),
        ),
      ],
    );
  }

  Widget _buildPlayerCard({
    required String name,
    required String avatarColor,
    required bool isCurrentUser,
    required bool isLeaving,
    required Player player,
  }) {
    final colorMap = {
      'red': Colors.red,
      'pink': Colors.pink,
      'orange': Colors.orange,
      'yellow': Colors.yellow,
      'green': Colors.green,
      'blue': Colors.blue,
      'indigo': Colors.indigo,
      'purple': Colors.purple,
    };

    final bgColor = colorMap[avatarColor] ?? Colors.blue;

    return GestureDetector(
      onTap: isCurrentUser ? _showProfileEditor : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCurrentUser ? const Color(0xFF9D4EDD) : Colors.white.withOpacity(0.1),
            width: isCurrentUser ? 2.5 : 1,
          ),
          boxShadow: isCurrentUser
              ? [
                  BoxShadow(
                    color: const Color(0xFF9D4EDD).withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: isCurrentUser ? const Color(0xFFFFC857) : const Color(0xFF7FE9DE),
                ),
                const SizedBox(width: 6),
                Text(
                  isCurrentUser ? 'You' : 'Joined',
                  style: const TextStyle(
                    color: Color(0xFFD1B7FF),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  void _showProfileEditor() {
    final currentPlayer = widget.session.players.firstWhere(
      (p) => p.id == widget.userId,
      orElse: () => Player(id: widget.userId, name: 'Player'),
    );

    showDialog(
      context: context,
      builder: (context) => PlayerProfileEditor(
        player: currentPlayer,
        onSave: (name, avatarColor) {
          Navigator.of(context).pop();
          
          setState(() {
            _displayPlayers[widget.userId] = Player(
              id: widget.userId,
              name: name,
              photoURL: avatarColor,
              score: currentPlayer.score,
              isDrawing: currentPlayer.isDrawing,
              isCreator: currentPlayer.isCreator,
            );
          });
          
          _saveProfileLocally(name, avatarColor);
          
          _gameService.updatePlayer(
            widget.session.id,
            widget.userId,
            name,
            avatarColor,
          );
        },
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.shade800.withOpacity(0.85),
                    Colors.deepPurple.shade900.withOpacity(0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.purpleAccent.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade600.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.purpleAccent.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.exit_to_app_rounded,
                    size: 32,
                    color: Colors.purpleAccent,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'Leave Waiting Room?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Description
                Text(
                  'Are you sure you want to exit? You can rejoin later.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                
                // Buttons
                Column(
                  children: [
                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.purpleAccent.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Stay',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Leave Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _gameService.leaveGame(widget.session.id);
                          widget.onBack();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Leave Room',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }

  Future<bool> _onBackPressed() async {
    _showExitConfirmation();
    return false;
  }

  Widget _buildRoomSettings() {
    final difficulty = widget.session.wordDifficulty;
    final difficultyColor = difficulty == 'easy'
        ? Colors.green
        : difficulty == 'hard'
            ? Colors.red
            : Colors.orange;

    final difficultyIcon = difficulty == 'easy'
        ? Icons.sentiment_satisfied
        : difficulty == 'hard'
            ? Icons.sentiment_very_dissatisfied
            : Icons.sentiment_neutral;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.people, color: Colors.white70, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.session.players.length}/${widget.session.maxPlayers}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'Players',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.loop, color: Colors.white70, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.session.maxRounds}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'Rounds',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.timer, color: Colors.cyan, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.session.roundTimeLimit}s',
                      style: const TextStyle(
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'Time',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Icon(difficultyIcon, color: difficultyColor, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      difficulty[0].toUpperCase() + difficulty.substring(1),
                      style: TextStyle(
                        color: difficultyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'Difficulty',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptySlot extends StatefulWidget {
  const _EmptySlot();

  @override
  State<_EmptySlot> createState() => _EmptySlotState();
}

class _EmptySlotState extends State<_EmptySlot> with TickerProviderStateMixin {
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          style: BorderStyle.solid,
        ),
        color: Colors.white.withOpacity(0.03),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _dotsController,
          builder: (context, child) {
            final progress = _dotsController.value;
            final dots = progress < 0.33 ? '.' : progress < 0.66 ? '..' : '...';
            return Text(
              'Waiting for\nplayer$dots',
              style: const TextStyle(
                color: Color(0xFFB595D4),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            );
          },
        ),
      ),
    );
  }
}