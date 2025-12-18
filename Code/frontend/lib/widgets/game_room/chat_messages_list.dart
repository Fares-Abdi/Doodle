import 'package:flutter/material.dart';
import 'chat_bubble.dart';

class ChatMessagesList extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final ScrollController controller;
  final String userId;

  const ChatMessagesList({Key? key, required this.messages, required this.controller, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'Chat messages\n(Drag divider)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isCurrentUser = message['userId'] == userId;
        return ChatBubble(message: message, isCurrentUser: isCurrentUser);
      },
    );
  }
}
