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
  
  static const int maxPlayersPerGame = 6;
  late Map<String, Player> _displayPlayers; // Local copy for UI updates

  @override
  void initState() {
    super.initState();
    _leavingPlayers = {};
    _previousPlayers = List.from(widget.session.players);
    _displayPlayers = {for (var p in widget.session.players) p.id: p}; // Local copy
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
  }

  /// Load saved player profile from local storage
  Future<void> _loadSavedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('player_name_${widget.userId}');
    
    if (savedName != null) {
      _nameController.text = savedName;
    }
  }

  /// Save player profile to local storage
  Future<void> _saveProfileLocally(String name, String avatarColor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('player_name_${widget.userId}', name);
    await prefs.setString('player_avatar_${widget.userId}', avatarColor);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Check if all players have exited the waiting room (should trigger room destruction)
  bool _haveAllPlayersExited() {
    return widget.session.players.isEmpty;
  }

  @override
  void didUpdateWidget(WaitingRoom oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Sync display players with parent changes
    // This ensures we get updated players from the stream
    _displayPlayers = {for (var p in widget.session.players) p.id: p};
    
    // Find players who left the game
    final currentPlayerIds = widget.session.players.map((p) => p.id).toSet();
    final previousPlayerIds = _previousPlayers.map((p) => p.id).toSet();
    
    // Players who were in previous list but not in current list have left
    final leftPlayerIds = previousPlayerIds.difference(currentPlayerIds);
    
    if (leftPlayerIds.isNotEmpty) {
      // Mark players as leaving for animation
      setState(() {
        _leavingPlayers.addAll(leftPlayerIds);
      });
      
      // After animation, remove them from leaving set
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _leavingPlayers.removeAll(leftPlayerIds);
          });
        }
      });
    }
    
    // Check if all players have exited - destroy/abort the room
    if (_haveAllPlayersExited() && !_roomDestroyed) {
      _roomDestroyed = true;
      _handleRoomDestruction();
    }
    
    // Update previous players list
    _previousPlayers = List.from(widget.session.players);
  }

  /// Handle room destruction when all players exit
  void _handleRoomDestruction() {
    // Show notification about room being destroyed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All players left. Room has been destroyed.'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.deepPurple,
      ),
    );
    
    // Go back to lobby after a short delay
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
            // Animated gradient background
            _buildAnimatedGradientBackground(),
            SafeArea(
              child: Column(
                children: [
                  // Header with back and profile buttons
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

                  // 👥 Players Grid
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildPlayersGrid(),
                    ),
                  ),

                  // ⏳ Waiting text & Connection status
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildConnectionStatus(),
                  ),

                  // ✅ Ready button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: widget.session.players.length >= 2 ? widget.onStartGame : null,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.black45,
                          elevation: 8,
                          disabledBackgroundColor: Colors.transparent,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: widget.session.players.length >= 2
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF6C2BD9),
                                      Color(0xFFE056FD),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.grey.withOpacity(0.3),
                                      Colors.grey.withOpacity(0.5),
                                    ],
                                  ),
                            borderRadius: const BorderRadius.all(Radius.circular(30)),
                          ),
                          child: Center(
                            child: Text(
                              widget.session.players.length >= 2 ? "START GAME" : "WAITING FOR PLAYERS",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
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
    );
  }

  Widget _buildAnimatedGradientBackground() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Create a smooth animated gradient with more visible color transitions
        final animValue = _animationController.value;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                // Smooth color transition for first color
                Color.lerp(
                  const Color(0xFF2C1447),
                  const Color(0xFF1f0a3d),
                  (sin(animValue * 6.28) + 1) / 2,
                )!,
                // Smooth color transition for second color  
                Color.lerp(
                  const Color(0xFF6C2BD9),
                  const Color(0xFFa855f7),
                  (sin(animValue * 6.28) + 1) / 2,
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
        // Display existing players
        ..._displayPlayers.values.map((player) {
          final isLeavingPlayer = _leavingPlayers.contains(player.id);
          
          return AnimatedOpacity(
            opacity: isLeavingPlayer ? 0.5 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: _buildPlayerCard(
              name: player.name,
              avatarColor: player.photoURL ?? 'blue',
              isCurrentUser: player.id == widget.userId,
              isLeaving: isLeavingPlayer,
              player: player,
            ),
          );
        }),
        // Display empty slots
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
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCurrentUser ? const Color(0xFFE056FD) : Colors.white12,
            width: isCurrentUser ? 2 : 1,
          ),
          boxShadow: isCurrentUser
              ? [
                  BoxShadow(
                    color: const Color(0xFFE056FD).withOpacity(0.4),
                    blurRadius: 12,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar circle
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
                  color: isCurrentUser ? Colors.yellow : Colors.greenAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  isCurrentUser ? 'You' : 'Joined',
                  style: const TextStyle(color: Color(0xFFEDE4FF)),
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
    // Show status message if players have exited
    if (_leavingPlayers.isNotEmpty) {
      final exitingCount = _leavingPlayers.length;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          '$exitingCount player${exitingCount > 1 ? 's' : ''} left the room',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.redAccent,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        'Players: ${_displayPlayers.length}/$maxPlayersPerGame',
        style: const TextStyle(
          color: Color(0xFFEDE4FF),
          fontSize: 16,
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
          // Close dialog first to dismiss keyboard
          Navigator.of(context).pop();
          
          // Update local display immediately for better UX
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
          
          // Save to local storage for persistence
          _saveProfileLocally(name, avatarColor);
          
          // Send update to backend
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
                // Send leave_game message before going back
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
    return false; // Prevent default back button behavior
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
          color: Colors.white24,
          style: BorderStyle.solid,
        ),
        color: Colors.white.withOpacity(0.04),
      ),
      child: const Center(
        child: Text(
          'Waiting for\nplayer...',
          style: TextStyle(
            color: Color(0xFFD1B7FF),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
