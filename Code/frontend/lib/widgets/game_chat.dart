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
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isCurrentUser = message['userId'] == widget.userId;
              final isCorrectGuess = message['isCorrectGuess'] ?? false;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 8,
                ),
                child: Align(
                  alignment: isCorrectGuess 
                      ? Alignment.center
                      : (isCurrentUser 
                          ? Alignment.centerRight 
                          : Alignment.centerLeft),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCorrectGuess
                          ? Colors.green.shade100
                          : (isCurrentUser
                              ? Colors.blue.shade100
                              : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                      border: isCorrectGuess
                          ? Border.all(color: Colors.green, width: 2)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['userName'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCorrectGuess
                                ? Colors.green
                                : Colors.black87,
                          ),
                        ),
                        Text(
                          message['message'],
                          style: TextStyle(
                            color: isCorrectGuess
                                ? Colors.green.shade800
                                : Colors.black87,
                            fontWeight: isCorrectGuess
                                ? FontWeight.bold
                                : FontWeight.normal,
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
        if (!widget.gameSession.players
            .firstWhere((p) => p.id == widget.userId)
            .isDrawing)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your guess...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _handleMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _handleMessage(_messageController.text),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
