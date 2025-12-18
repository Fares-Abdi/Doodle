import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isCurrentUser;

  const ChatBubble({Key? key, required this.message, required this.isCurrentUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
}
