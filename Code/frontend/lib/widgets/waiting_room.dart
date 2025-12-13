import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_session.dart';
import '../services/game_service.dart';
import 'player_avatar.dart';
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

class _WaitingRoomState extends State<WaitingRoom> {
  late Set<String> _animatedPlayers;
  late Set<String> _leavingPlayers;
  late List<Player> _previousPlayers;
  final GameService _gameService = GameService();
  bool _roomDestroyed = false;
  late TextEditingController _nameController;
  bool _isEditingName = false;
  late String _selectedAvatarColor;
  late Map<String, Player> _displayPlayers; // Local copy for UI updates
  
  static const List<Color> avatarColors = [
    Colors.red,
    Colors.pink,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _animatedPlayers = {};
    _leavingPlayers = {};
    _previousPlayers = List.from(widget.session.players);
    _displayPlayers = {for (var p in widget.session.players) p.id: p}; // Local copy
    final currentPlayer = widget.session.players.firstWhere(
      (p) => p.id == widget.userId,
      orElse: () => Player(id: widget.userId, name: 'Player'),
    );
    _nameController = TextEditingController(text: currentPlayer.name);
    _selectedAvatarColor = currentPlayer.photoURL ?? 'blue';
    _loadSavedProfile();
  }

  /// Load saved player profile from local storage
  Future<void> _loadSavedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('player_name_${widget.userId}');
    final savedColor = prefs.getString('player_avatar_${widget.userId}');
    
    if (savedName != null) {
      _nameController.text = savedName;
    }
    if (savedColor != null) {
      setState(() {
        _selectedAvatarColor = savedColor;
      });
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
    super.dispose();
  }

  /// Check if a player has exited the waiting room
  bool _hasPlayerExited(String playerId) {
    return !widget.session.players.any((p) => p.id == playerId);
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
      child: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.fromARGB(255, 39, 28, 85), Color.fromARGB(255, 96, 30, 144)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar for waiting room
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPlayersCountText(),
                          const SizedBox(height: 32),
                          _buildPlayerAvatars(),
                          const SizedBox(height: 40),
                          _buildStartButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
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
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: _showProfileEditor,
            tooltip: 'Edit Profile',
          ),
        ],
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
            _selectedAvatarColor = avatarColor;
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

  Widget _buildPlayersCountText() {
    return Text(
      '${_displayPlayers.length} players are in the waiting room',
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white
      ),
    );
  }

  Widget _buildPlayerAvatars() {
    // Show current players plus leaving players (for animation)
    final displayList = <Player>[..._displayPlayers.values];
    
    // Add back players who are leaving so we can animate them out
    for (final leavingId in _leavingPlayers) {
      // Check if player is already in display list
      if (displayList.any((p) => p.id == leavingId)) {
        continue;
      }
      
      // Try to find the leaving player in previous list
      for (final player in _previousPlayers) {
        if (player.id == leavingId) {
          displayList.add(player);
          break;
        }
      }
    }
    
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 24,
      runSpacing: 24,
      children: displayList.map((player) {
        final isNewPlayer = !_animatedPlayers.contains(player.id) && 
                           !_leavingPlayers.contains(player.id);
        final isLeavingPlayer = _leavingPlayers.contains(player.id);
        
        return PlayerAvatar(
          player: player,
          isCurrentUser: player.id == widget.userId,
          isNewPlayer: isNewPlayer,
          isLeavingPlayer: isLeavingPlayer,
          onAnimationEnd: () {
            if (mounted && !isLeavingPlayer) {
              setState(() {
                _animatedPlayers.add(player.id);
              });
            }
          },
        );
      }).toList(),
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
    return const SizedBox.shrink();
  }

  Widget _buildStartButton() {
    return ElevatedButton(
      onPressed: widget.session.players.length >= 2 ? widget.onStartGame : null,
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
        widget.session.players.length >= 2 ? 'START GAME' : 'WAITING FOR PLAYERS',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
