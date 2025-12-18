import 'package:flutter/material.dart';
import '../models/game_session.dart';
import 'enhanced_leaderboard.dart';
import '../services/game_service.dart';
import '../services/websocket_service.dart';
import '../utils/audio_mixin.dart';
import '../utils/game_sounds.dart';
import '../utils/avatar_color_helper.dart';

class ChatPanel extends StatefulWidget {
  final bool visible;
  final Animation<double> animation;
  final GameSession session;
  final String userId;
  final String userName;

  const ChatPanel({
    Key? key,
    required this.visible,
    required this.animation,
    required this.session,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> with TickerProviderStateMixin, WidgetsBindingObserver, AudioMixin {
  final double _initialLeaderboardHeight = 0.38; // 38% by default - shows full gold medal position
  late double _leaderboardHeight;
  late double _heightBeforeKeyboard;
  late double _panelContentHeight;
  bool _isDragging = false;
  bool _isHoveringDivider = false;
  double _lastViewInsetsBottom = 0.0;
  late AnimationController _dragController;
  late AnimationController _dividerExpandController;
  late Animation<double> _dividerExpandAnimation;
  
  // GameChat variables
  final TextEditingController _messageController = TextEditingController();
  final GameService _gameService = GameService();
  final WebSocketService _wsService = WebSocketService();
  final List<Map<String, dynamic>> _messages = [];
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _leaderboardHeight = _initialLeaderboardHeight;
    _heightBeforeKeyboard = _initialLeaderboardHeight;
    _scrollController = ScrollController();
    
    _dragController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Controller for divider expand/collapse animation
    _dividerExpandController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Smooth curve animation from 0 to 1
    _dividerExpandAnimation = CurvedAnimation(
      parent: _dividerExpandController,
      curve: Curves.easeInOutCubic,
    );
    
    // Start with divider expanded
    _dividerExpandController.value = 1.0;
    
    // Listen for chat messages
    _wsService.chatMessages.listen((message) {
      if (message['gameId'] == widget.session.id) {
        setState(() {
          _messages.add(message['payload']);
        });
        // Auto scroll to latest message
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToBottom();
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dragController.dispose();
    _dividerExpandController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    print('📱 didChangeMetrics called, keyboard height: $viewInsetsBottom');
    _handleKeyboardVisibility(viewInsetsBottom);
  }

  void _handleKeyboardVisibility(double viewInsetsBottom) {
    final keyboardVisible = viewInsetsBottom > 0;
    final keyboardWasVisible = _lastViewInsetsBottom > 0;
    
    print('🔍 Keyboard check - visible: $keyboardVisible, was visible: $keyboardWasVisible, isDragging: $_isDragging');
    
    // Only react if keyboard visibility state changed and not dragging
    if (!_isDragging && keyboardVisible != keyboardWasVisible) {
      print('✅ Keyboard state changed! Updating leaderboard height');
      setState(() {
        if (keyboardVisible) {
          // Keyboard appeared: set to 46%
          _heightBeforeKeyboard = _leaderboardHeight;
          _leaderboardHeight = 0.46;
          _dividerExpandController.forward();
          print('⌨️ Keyboard visible - setting height to 46%');
        } else {
          // Keyboard disappeared: expand to 100%
          _leaderboardHeight = 1.0;
          _dividerExpandController.reverse();
          print('🚫 Keyboard hidden - setting height to 100%');
        }
      });
    }
    
    _lastViewInsetsBottom = viewInsetsBottom;
  }

  void _handleKeyboardVisibilityFromBuild(double viewInsetsBottom) {
    final keyboardVisible = viewInsetsBottom > 0;
    final keyboardWasVisible = _lastViewInsetsBottom > 0;
    
    print('🔍 [BUILD] Keyboard check - visible: $keyboardVisible, was visible: $keyboardWasVisible, isDragging: $_isDragging');
    
    // Only react if keyboard visibility state changed and not dragging
    if (!_isDragging && keyboardVisible != keyboardWasVisible) {
      print('✅ [BUILD] Keyboard state changed! Updating leaderboard height');
      setState(() {
        if (keyboardVisible) {
          // Keyboard appeared: set to 46%
          _heightBeforeKeyboard = _leaderboardHeight;
          _leaderboardHeight = 0.46;
          _dividerExpandController.forward();
          print('⌨️ [BUILD] Keyboard visible - setting height to 46%');
        } else {
          // Keyboard disappeared: expand to 100%
          _leaderboardHeight = 1.0;
          _dividerExpandController.reverse();
          print('🚫 [BUILD] Keyboard hidden - setting height to 100%');
        }
      });
    }
    
    _lastViewInsetsBottom = viewInsetsBottom;
  }

  void _onChatInputFocused() {
    if (!_isDragging && _leaderboardHeight > 0.0) {
      setState(() {
        _heightBeforeKeyboard = _leaderboardHeight;
        _leaderboardHeight = 0.0;
      });
      // Collapse divider animation when keyboard opens
      _dividerExpandController.reverse();
    }
  }

  void _onChatInputUnfocused() {
    if (!_isDragging) {
      setState(() {
        // Always restore to the height before keyboard appeared
        _leaderboardHeight = _heightBeforeKeyboard;
        // If somehow it's still 0, restore to initial
        if (_leaderboardHeight == 0.0) {
          _leaderboardHeight = _initialLeaderboardHeight;
          _heightBeforeKeyboard = _initialLeaderboardHeight;
        }
      });
      // Expand divider animation back when keyboard closes
      _dividerExpandController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Check keyboard visibility directly in build (like the test screen does)
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final keyboardVisible = viewInsetsBottom > 0;
    final keyboardWasVisible = _lastViewInsetsBottom > 0;
    
    // Update keyboard state if it changed
    if (!_isDragging && keyboardVisible != keyboardWasVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleKeyboardVisibilityFromBuild(viewInsetsBottom);
      });
    }
    
    // Responsive width: 85% on small screens, 75% on larger
    final panelWidth = screenWidth < 400 
        ? screenWidth * 0.85 
        : screenWidth * 0.75;

    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(widget.animation),
        child: Container(
          width: panelWidth,
          constraints: BoxConstraints(
            maxWidth: 420,
            minWidth: 280,
          ),
          clipBehavior: Clip.none,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(-8, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with players count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade500,
                      Colors.deepPurple.shade700,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.deepPurple.shade900.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.shade900.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                MediaQuery.of(context).viewInsets.bottom > 0
                                    ? '⌨️ Keyboard Visible'
                                    : '✓ Keyboard Hidden',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Game in progress',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.75),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.35),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${widget.session.players.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Leaderboard with sparkle overflow effect
              Container(
                height: _getLeaderboardHeight(context),
                clipBehavior: Clip.none,
                decoration: const BoxDecoration(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    EnhancedLeaderboard(
                      session: widget.session,
                      userId: widget.userId,
                    ),
                  ],
                ),
              ),
              
              // Enhanced draggable divider with expand animation
              _buildEnhancedDivider(),
              
              // Chat section - takes remaining space
              _buildChatSection(),
            ],
          ),
        ),
      ),
    );
  }

  double _getLeaderboardHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = 130.0;
    final dividerHeight = 28.0;
    
    final availableHeight = screenHeight - headerHeight - dividerHeight;
    return availableHeight * _leaderboardHeight;
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
          setState(() => _isDragging = true);
          _dragController.forward();
        },
        onVerticalDragUpdate: (details) {
          setState(() {
            final totalContent = MediaQuery.of(context).size.height - 100;
            final newHeight = _leaderboardHeight + (details.delta.dy / totalContent);
            _leaderboardHeight = newHeight.clamp(0.0, 0.95);
            final percentage = (_leaderboardHeight * 100).toStringAsFixed(1);
            print('📊 Divider dragging: $percentage%');
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
              height: 12, // Fixed height
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
                        width: 120, // Fixed width - always stays same size
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleMessage(String message) {
    if (message.trim().isEmpty) return;

    bool isCorrectGuess = message.trim().toLowerCase() == 
        widget.session.currentWord?.toLowerCase() &&
        !widget.session.players.firstWhere((p) => p.id == widget.userId).isDrawing;

    if (isCorrectGuess) {
      playCorrectGuess();
      _gameService.handleCorrectGuess(widget.session.id, widget.userId);
    } else {
      playWrongGuess();
    }

    _wsService.sendMessage('chat_message', widget.session.id, {
      'message': isCorrectGuess ? '🎉 Correctly guessed the word!' : message,
      'userId': widget.userId,
      'userName': widget.userName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'isCorrectGuess': isCorrectGuess,
    });

    _messageController.clear();
  }

  Widget _buildChatSection() {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Messages list with avatar and names
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isCurrentUser = message['userId'] == widget.userId;
                  final isCorrectGuess = message['isCorrectGuess'] ?? false;
                  
                  Player? playerFromSession;
                  try {
                    playerFromSession = widget.session.players.firstWhere(
                      (p) => p.id == message['userId'],
                    );
                  } catch (e) {
                    playerFromSession = null;
                  }
                  
                  final userName = playerFromSession?.name ?? (message['userName'] as String? ?? 'Unknown');
                  final userColor = AvatarColorHelper.getColorFromName(userName);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: isCorrectGuess
                        ? _buildSystemMessage(message, userName)
                        : _buildChatBubble(
                            context,
                            message,
                            isCurrentUser,
                            userName,
                            userColor,
                          ),
                  );
                },
              ),
            ),
            // Input area
            _buildMessageInput(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMessage(Map<String, dynamic> message, String userName) {
    final guessMessage = '🎉 $userName found the word!';
    
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade400,
              Colors.green.shade500,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          guessMessage,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildChatBubble(
    BuildContext context,
    Map<String, dynamic> message,
    bool isCurrentUser,
    String userName,
    Color userColor,
  ) {
    final messageText = message['message'] as String? ?? '';
    
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: isCurrentUser
            ? const EdgeInsets.only(right: 4, left: 40)
            : const EdgeInsets.only(left: 4, right: 40),
        child: Row(
          mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isCurrentUser)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 2),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: userColor,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isCurrentUser
                      ? LinearGradient(
                          colors: [
                            Colors.deepPurple.shade400,
                            Colors.deepPurple.shade500,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: !isCurrentUser ? Colors.grey.shade100 : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isCurrentUser
                          ? Colors.deepPurple.withOpacity(0.2)
                          : Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                        color: isCurrentUser
                            ? Colors.white.withOpacity(0.9)
                            : Colors.grey.shade700,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      messageText,
                      style: TextStyle(
                        color: isCurrentUser ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            if (isCurrentUser)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: userColor,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    final isUserDrawing = widget.session.players
        .firstWhere((p) => p.id == widget.userId)
        .isDrawing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.deepPurple.shade200,
                    width: 1.2,
                  ),
                ),
                child: Focus(
                  onFocusChange: (hasFocus) {
                    if (hasFocus) {
                      _onChatInputFocused();
                    } else {
                      _onChatInputUnfocused();
                    }
                  },
                  child: TextField(
                    controller: _messageController,
                    enabled: !isUserDrawing,
                    maxLines: null,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: isUserDrawing ? 'Drawing...' : 'Guess...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                    onSubmitted: !isUserDrawing ? _handleMessage : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade400,
                    Colors.deepPurple.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 6,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: !isUserDrawing ? () => _handleMessage(_messageController.text) : null,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
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
