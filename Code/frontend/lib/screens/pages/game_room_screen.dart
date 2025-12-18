import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;
import '../../models/game_session.dart';
import '../../services/game_service.dart';
import '../../utils/audio_mixin.dart';
import '../../utils/game_sounds.dart';
import '../../widgets/waiting_room.dart';
import '../../widgets/round_transition.dart';
import '../../widgets/game_over_screen.dart';
import '../../widgets/game_board.dart';
import '../../widgets/enhanced_leaderboard.dart';

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

class _GameRoomScreenState extends State<GameRoomScreen> with TickerProviderStateMixin, AudioMixin, WidgetsBindingObserver {
  final GameService _gameService = GameService();
  late Stream<GameSession> _gameStream;
  late GameSession _currentGameSession;
  late AnimationController _chatPanelController;
  late Animation<double> _chatPanelAnimation;
  bool _isChatVisible = false;
  final TextEditingController _chatMessageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  late ScrollController _scrollController;
  
  // Divider variables
  late double _leaderboardHeight;
  late double _targetLeaderboardHeight;
  late double _heightBeforeKeyboard;
  bool _isDragging = false;
  bool _isHoveringDivider = false;
  double _lastViewInsetsBottom = 0.0;
  late AnimationController _dragController;
  late AnimationController _dividerExpandController;
  late Animation<double> _dividerExpandAnimation;

  @override
  void initState() {
    super.initState();
    _gameStream = _gameService.subscribeToGame(widget.gameId);
    _listenToGameState();
    _scrollController = ScrollController();
    
    _chatPanelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _chatPanelAnimation = CurvedAnimation(
      parent: _chatPanelController,
      curve: Curves.easeInOut,
    );
    
    // Listen for chat messages
    _gameService.wsService.chatMessages.listen((message) {
      if (message['gameId'] == widget.gameId) {
        setState(() {
          _messages.add(message['payload']);
        });
        // Auto scroll to latest message
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToBottom();
        });
      }
    });
    
    // Initialize divider animation controllers
    _leaderboardHeight = 0.38;
    _targetLeaderboardHeight = 0.38;
    _heightBeforeKeyboard = 0.38;
    
    _dragController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _dividerExpandController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _dividerExpandAnimation = CurvedAnimation(
      parent: _dividerExpandController,
      curve: Curves.easeInOutCubic,
    );
    
    _dividerExpandController.value = 1.0;
    
    // Listen to animation changes and rebuild
    _dividerExpandAnimation.addListener(() {
      setState(() {});
    });

    // Add observer to handle app lifecycle events
    WidgetsBinding.instance.addObserver(this);
  }

  void _listenToGameState() {
    _gameStream.listen((gameSession) {
      // Store the current game session for access in message handling
      _currentGameSession = gameSession;
      
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
  void didChangeMetrics() {
    super.didChangeMetrics();
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    _handleKeyboardVisibility(viewInsetsBottom);
  }
  
  void _handleKeyboardVisibility(double viewInsetsBottom) {
    final keyboardVisible = viewInsetsBottom > 0;
    final keyboardWasVisible = _lastViewInsetsBottom > 0;
    
    if (!_isDragging && keyboardVisible != keyboardWasVisible) {
      if (keyboardVisible) {
        // Store current position before animating up
        setState(() {
          _heightBeforeKeyboard = _leaderboardHeight;
          _targetLeaderboardHeight = 0.0;
        });
        _dividerExpandController.reset();
        _dividerExpandController.forward().then((_) {
          // Sync _leaderboardHeight after animation completes
          if (mounted) {
            setState(() {
              _leaderboardHeight = 0.0;
            });
          }
        });
      } else {
        // When keyboard closes, animate back to stored position
        // Don't change _leaderboardHeight here, let the animation handle it
        _dividerExpandController.reverse().then((_) {
          // After animation completes, ensure final position is set
          if (mounted) {
            setState(() {
              _leaderboardHeight = _heightBeforeKeyboard;
            });
          }
        });
      }
    }
    
    _lastViewInsetsBottom = viewInsetsBottom;
  }
  
  double _getLeaderboardHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = 130.0;
    final dividerHeight = 28.0;
    
    double height;
    
    if (_isDragging || !_dividerExpandController.isAnimating) {
      // When dragging or not animating, use direct value
      height = _leaderboardHeight;
    } else {
      // During animation, interpolate correctly based on direction
      // When forward (keyboard opening): animate from _heightBeforeKeyboard to 0
      // When reverse (keyboard closing): animate from 0 to _heightBeforeKeyboard
      if (_dividerExpandController.status == AnimationStatus.forward) {
        // Going up (0 -> 1): from _heightBeforeKeyboard to 0
        height = lerpDouble(_heightBeforeKeyboard, _targetLeaderboardHeight, _dividerExpandAnimation.value) ?? _leaderboardHeight;
      } else {
        // Going down (1 -> 0): from 0 to _heightBeforeKeyboard
        // We need to invert because reverse goes from 1 to 0, but we want to go from 0 to target
        height = lerpDouble(0.0, _heightBeforeKeyboard, 1.0 - _dividerExpandAnimation.value) ?? _leaderboardHeight;
      }
    }
    
    final availableHeight = screenHeight - headerHeight - dividerHeight;
    return availableHeight * height;
  }

  Widget _buildEnhancedDivider() {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      onEnter: (_) {
        setState(() => _isHoveringDivider = true);
        _dragController.forward();
      },
      onExit: (_) {
        setState(() => _isHoveringDivider = false);
        if (!_isDragging) _dragController.reverse();
      },
      child: GestureDetector(
        onVerticalDragStart: (_) {
          setState(() {
            _isDragging = true;
            // Stop any ongoing animation
            _dividerExpandController.stop();
            
            // Calculate current visual position based on animation state
            if (_dividerExpandController.isAnimating) {
              if (_dividerExpandController.status == AnimationStatus.forward) {
                // Going up: interpolate from _heightBeforeKeyboard to 0
                _leaderboardHeight = lerpDouble(_heightBeforeKeyboard, 0.0, _dividerExpandAnimation.value) ?? _leaderboardHeight;
              } else {
                // Going down: interpolate from 0 to _heightBeforeKeyboard
                _leaderboardHeight = lerpDouble(0.0, _heightBeforeKeyboard, 1.0 - _dividerExpandAnimation.value) ?? _leaderboardHeight;
              }
            }
            
            // Sync all height variables to current position
            _targetLeaderboardHeight = _leaderboardHeight;
            _heightBeforeKeyboard = _leaderboardHeight;
          });
          _dragController.forward();
        },
        onVerticalDragUpdate: (details) {
          setState(() {
            final totalContent = MediaQuery.of(context).size.height - 100;
            final newHeight = _leaderboardHeight + (details.delta.dy / totalContent);
            _leaderboardHeight = newHeight.clamp(0.0, 0.95);
            _targetLeaderboardHeight = _leaderboardHeight;
            _heightBeforeKeyboard = _leaderboardHeight; // Keep this synced
            final percentage = (_leaderboardHeight * 100).toStringAsFixed(1);
            print('📊 [GAME] Divider dragging: $percentage%');
          });
        },
        onVerticalDragEnd: (_) {
          setState(() => _isDragging = false);
          if (!_isHoveringDivider) _dragController.reverse();
        },
        child: AnimatedBuilder(
          animation: _dividerExpandAnimation,
          builder: (context, child) {
            final expandValue = _dividerExpandAnimation.value;
            
            return Container(
              height: 12,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade400,
                    Colors.deepPurple.shade500,
                  ],
                ),
              ),
              child: Center(
                child: AnimatedBuilder(
                  animation: _dragController,
                  builder: (context, child) {
                    final animValue = Curves.easeOut.transform(_dragController.value);
                    return Opacity(
                      opacity: (0.3 + (0.3 * expandValue)) + (0.2 * animValue),
                      child: Container(
                        width: 120,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.95),
                              Colors.white.withOpacity(0.8),
                              Colors.grey.shade300.withOpacity(0.9),
                              Colors.white.withOpacity(0.85),
                            ],
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15 * (0.5 + (0.5 * expandValue))),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // When app comes back to foreground, resume the game music immediately
      // The main.dart already paused it, so just resume it
      resumeBackgroundMusic();
    }
  }

  @override
  void dispose() {
    // Remove observer when screen is disposed
    WidgetsBinding.instance.removeObserver(this);
    
    // Send leave_game message to server when leaving the room
    _gameService.leaveGame(widget.gameId);
    _chatPanelController.dispose();
    _dragController.dispose();
    _dividerExpandController.dispose();
    _chatMessageController.dispose();
    _scrollController.dispose();
    // Ensure lobby music plays when returning to lobby
    playBackgroundMusic(GameSounds.lobbyMusic);
    super.dispose();
  }


  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleMessageSend(String message) {
    if (message.trim().isEmpty) return;

    // Check if answer is correct
    bool isCorrectGuess = false;
    if (_currentGameSession.currentWord != null) {
      // Find current user to check if they are the drawer
      final currentUser = _currentGameSession.players
          .firstWhere((p) => p.id == widget.userId, orElse: () => Player(id: '', name: '', isDrawing: false));
      
      // Only check if user is not the drawer and message matches the word (case-insensitive)
      if (!currentUser.isDrawing && 
          message.toLowerCase().trim() == _currentGameSession.currentWord!.toLowerCase().trim()) {
        isCorrectGuess = true;
      }
    }

    if (isCorrectGuess) {
      // Correct guess! Play sound and notify server
      playCorrectGuess();
      _gameService.handleCorrectGuess(widget.gameId, widget.userId);
    } else {
      // Wrong guess - play wrong sound
      playWrongGuess();
    }

    // Send message to server
    _gameService.wsService.sendMessage('chat_message', widget.gameId, {
      'message': isCorrectGuess ? '🎉 Correctly guessed the word!' : message,
      'userId': widget.userId,
      'userName': widget.userName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'isCorrectGuess': isCorrectGuess,
    });

    _chatMessageController.clear();
  }

  Widget _buildChatBubble(Map<String, dynamic> message, bool isCurrentUser) {
    final messageText = message['message'] as String? ?? '';
    final userName = message['userName'] as String? ?? 'Unknown';
    final isCorrectGuess = message['isCorrectGuess'] ?? false;

    if (isCorrectGuess) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade500],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '🎉 $userName found the word!',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isCurrentUser
              ? LinearGradient(
                  colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade500],
                )
              : null,
          color: !isCurrentUser ? Colors.grey.shade100 : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              userName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: isCurrentUser ? Colors.white.withOpacity(0.9) : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              messageText,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
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
            
            // Chat panel on the right side with keyboard-responsive divider
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(_chatPanelAnimation),
                child: Container(
                  width: 350,
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Leaderboard
                      Container(
                        height: _getLeaderboardHeight(context),
                        clipBehavior: Clip.none,
                        child: EnhancedLeaderboard(
                          session: session,
                          userId: widget.userId,
                        ),
                      ),
                      
                      // Divider with drag functionality
                      _buildEnhancedDivider(),
                      
                      // Chat messages area (Expanded)
                      Expanded(
                        child: Container(
                          color: Colors.grey.shade100,
                          child: _messages.isEmpty
                              ? Center(
                                  child: Text(
                                    'Chat messages\n(Drag divider)',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                  itemCount: _messages.length,
                                  itemBuilder: (context, index) {
                                    final message = _messages[index];
                                    final isCurrentUser = message['userId'] == widget.userId;
                                    return _buildChatBubble(message, isCurrentUser);
                                  },
                                ),
                        ),
                      ),
                      
                      // Message input - fixed at bottom of panel (not movable by divider)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        padding: EdgeInsets.only(
                          left: 12,
                          right: 12,
                          top: 8,
                          bottom: 8 + (MediaQuery.of(context).viewInsets.bottom == 0 ? _lastViewInsetsBottom : 0),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _chatMessageController,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Colors.deepPurple,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.deepPurple.shade500,
                                    Colors.deepPurple.shade600,
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () {
                                  if (_chatMessageController.text.isNotEmpty) {
                                    _handleMessageSend(_chatMessageController.text);
                                  }
                                },
                                icon: const Icon(Icons.send, color: Colors.white),
                                iconSize: 20,
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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