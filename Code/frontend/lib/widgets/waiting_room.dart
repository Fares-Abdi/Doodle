import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../models/game_session.dart';
import '../services/game_service.dart';
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

class _WaitingRoomState extends State<WaitingRoom> with TickerProviderStateMixin {
  late Set<String> _leavingPlayers;
  late List<Player> _previousPlayers;
  final GameService _gameService = GameService();
  bool _roomDestroyed = false;
  late TextEditingController _nameController;
  late AnimationController _animationController;
  late AnimationController _buttonGlowController;
  late AnimationController _playerJoinController;
  
  static const int maxPlayersPerGame = 6;
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
                  const SizedBox(height: 20),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildPlayersGrid(),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildConnectionStatus(),
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
    final emptySlots = maxPlayersPerGame - _displayPlayers.length;
    
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

  Widget _buildConnectionStatus() {
    if (_playerLeftMessage != null) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                  ),
                  child: Text(
                    _playerLeftMessage!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'Players: ${_displayPlayers.length}/$maxPlayersPerGame',
        style: const TextStyle(
          color: Color(0xFFD1B7FF),
          fontSize: 16,
          fontWeight: FontWeight.w500,
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit Game?'),
          content: const Text('Are you sure you want to leave the game?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _gameService.leaveGame(widget.session.id);
                widget.onBack();
              },
              child: const Text('Exit', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onBackPressed() async {
    _showExitConfirmation();
    return false;
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

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
      child: const Center(
        child: Text(
          'Waiting for\nplayer...',
          style: TextStyle(
            color: Color(0xFFB595D4),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}