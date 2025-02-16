import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/game_session.dart';
import '../services/game_service.dart';

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

  void _handleMessage(String message) {
    if (message.trim().isEmpty) return;

    bool isCorrectGuess = message.trim().toLowerCase() == 
        widget.gameSession.currentWord?.toLowerCase() &&
        !widget.gameSession.players.firstWhere((p) => p.id == widget.userId).isDrawing;

    if (isCorrectGuess) {
      // Correct guess!
      _gameService.handleCorrectGuess(widget.gameSession.id, widget.userId);
    }

    // Send message to Firebase with correct guess flag
    FirebaseDatabase.instance
        .ref()
        .child('game_chats')
        .child(widget.gameSession.id)
        .push()
        .set({
      'message': isCorrectGuess ? '🎉 Correctly guessed the word!' : message,
      'userId': widget.userId,
      'userName': widget.userName,
      'timestamp': ServerValue.timestamp,
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
          child: StreamBuilder(
            stream: FirebaseDatabase.instance.ref().child('game_chats')
                .child(widget.gameSession.id)
                .orderByChild('timestamp')
                .onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(
                child: CircularProgressIndicator());

              final messages = <Map<String, dynamic>>[];
              if (snapshot.data?.snapshot.value != null) {
                final messagesMap = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map<Object?, Object?>);
                messages.addAll(messagesMap.values.map((value) => 
                    Map<String, dynamic>.from(value as Map<Object?, Object?>)));
                messages.sort((a, b) => 
                    (a['timestamp'] as int).compareTo(b['timestamp'] as int));
              }

              return ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
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
