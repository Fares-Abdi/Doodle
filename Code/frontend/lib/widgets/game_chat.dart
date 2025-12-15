import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../services/game_service.dart';
import '../services/websocket_service.dart';

class GameChat extends StatefulWidget {
  final GameSession gameSession;
  final String userId;
  final String userName;

  const GameChat({
    Key? key,
    required this.gameSession,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<GameChat> createState() => _GameChatState();
}

class _GameChatState extends State<GameChat> {
  final TextEditingController _messageController = TextEditingController();
  final GameService _gameService = GameService();
  final WebSocketService _wsService = WebSocketService();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    // Listen for chat messages
    _wsService.chatMessages.listen((message) {
      if (message['gameId'] == widget.gameSession.id) {
        setState(() {
          _messages.add(message['payload']);
        });
      }
    });
  }

  void _handleMessage(String message) {
    if (message.trim().isEmpty) return;

    bool isCorrectGuess = message.trim().toLowerCase() == 
        widget.gameSession.currentWord?.toLowerCase() &&
        !widget.gameSession.players.firstWhere((p) => p.id == widget.userId).isDrawing;

    if (isCorrectGuess) {
      // Correct guess!
      _gameService.handleCorrectGuess(widget.gameSession.id, widget.userId);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isCurrentUser = message['userId'] == widget.userId;
              final isCorrectGuess = message['isCorrectGuess'] ?? false;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Align(
                  alignment: isCorrectGuess 
                      ? Alignment.center
                      : (isCurrentUser 
                          ? Alignment.centerRight 
                          : Alignment.centerLeft),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.5,
                    ),
                    decoration: BoxDecoration(
                      gradient: isCorrectGuess
                          ? LinearGradient(
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade500,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : (isCurrentUser
                              ? LinearGradient(
                                  colors: [
                                    Colors.deepPurple.shade400,
                                    Colors.deepPurple.shade500,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null),
                      color: !isCurrentUser && !isCorrectGuess 
                          ? Colors.grey.shade100 
                          : null,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isCurrentUser ? 20 : 4),
                        bottomRight: Radius.circular(isCurrentUser ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isCorrectGuess
                              ? Colors.green.withOpacity(0.25)
                              : (isCurrentUser
                                  ? Colors.deepPurple.withOpacity(0.25)
                                  : Colors.black.withOpacity(0.08)),
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isCurrentUser 
                          ? CrossAxisAlignment.end 
                          : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message['userName'],
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: isCurrentUser || isCorrectGuess
                                ? Colors.white
                                : Colors.grey.shade700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          message['message'],
                          style: TextStyle(
                            color: isCurrentUser || isCorrectGuess
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: isCorrectGuess
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 15,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.deepPurple.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    enabled: !widget.gameSession.players
                        .firstWhere((p) => p.id == widget.userId)
                        .isDrawing,
                    decoration: InputDecoration(
                      hintText: widget.gameSession.players
                              .firstWhere((p) => p.id == widget.userId)
                              .isDrawing
                          ? 'You are drawing...'
                          : 'Type your guess...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: _handleMessage,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: !widget.gameSession.players
                            .firstWhere((p) => p.id == widget.userId)
                            .isDrawing
                        ? () => _handleMessage(_messageController.text)
                        : null,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
