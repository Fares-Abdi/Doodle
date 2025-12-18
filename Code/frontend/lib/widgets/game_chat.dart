import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../services/game_service.dart';
import '../services/websocket_service.dart';
import '../utils/audio_mixin.dart';
import '../utils/game_sounds.dart';
import '../utils/avatar_color_helper.dart';

class GameChat extends StatefulWidget {
  final GameSession gameSession;
  final String userId;
  final String userName;
  final VoidCallback? onInputFocused;
  final VoidCallback? onInputUnfocused;

  const GameChat({
    Key? key,
    required this.gameSession,
    required this.userId,
    required this.userName,
    this.onInputFocused,
    this.onInputUnfocused,
  }) : super(key: key);

  @override
  State<GameChat> createState() => _GameChatState();
}

class _GameChatState extends State<GameChat> with AudioMixin {
  final TextEditingController _messageController = TextEditingController();
  final GameService _gameService = GameService();
  final WebSocketService _wsService = WebSocketService();
  final List<Map<String, dynamic>> _messages = [];
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Listen for chat messages
    _wsService.chatMessages.listen((message) {
      if (message['gameId'] == widget.gameSession.id) {
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
        widget.gameSession.currentWord?.toLowerCase() &&
        !widget.gameSession.players.firstWhere((p) => p.id == widget.userId).isDrawing;

    if (isCorrectGuess) {
      // Correct guess!
      playCorrectGuess();
      _gameService.handleCorrectGuess(widget.gameSession.id, widget.userId);
    } else {
      // Wrong guess
      playWrongGuess();
    }

    // Send message through WebSocket
    _wsService.sendMessage('chat_message', widget.gameSession.id, {
      'message': isCorrectGuess ? '🎉 Correctly guessed the word!' : message,
      'userId': widget.userId,
      'userName': widget.userName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'isCorrectGuess': isCorrectGuess,
    });

    // Clear the input field
    _messageController.clear();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
              
              // Look up player from session to get current name (not stored name)
              Player? playerFromSession;
              try {
                playerFromSession = widget.gameSession.players.firstWhere(
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
            // Avatar on left for other users
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
            // Chat bubble
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
                    // Username
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
                    // Message
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
            // Avatar on right for current user
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
    final isUserDrawing = widget.gameSession.players
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
                      widget.onInputFocused?.call();
                    } else {
                      widget.onInputUnfocused?.call();
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
            // Send button
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
