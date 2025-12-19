import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import 'chat_bubble.dart';

class ChatMessagesList extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final ScrollController controller;
  final String userId;
  final GameSession session;

  const ChatMessagesList({Key? key, required this.messages, required this.controller, required this.userId, required this.session}) : super(key: key);

  Widget _buildRoundDivider(int roundNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 2,
              color: Colors.grey.shade400,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'round ${roundNumber }', // ADD BACK THE + 1
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [];
    
    if (messages.isEmpty) {
      // No messages yet, just show current round divider
      items.add(_buildRoundDivider(session.currentRound));
    } else {
      // Track the last round we've shown a divider for
      int? lastDividerRound;
      
      for (int i = 0; i < messages.length; i++) {
        final message = messages[i];
        final messageRound = message['roundNumber'] ?? 0;
        
        // Show divider if this is a new round we haven't shown yet
        if (lastDividerRound == null || messageRound != lastDividerRound) {
          items.add(_buildRoundDivider(messageRound));
          lastDividerRound = messageRound;
        }
        
        items.add(
          ChatBubble(
            message: message,
            isCurrentUser: message['userId'] == userId,
            session: session,
          ),
        );
      }
      
      // If current round has no messages yet, show its divider at the end
      if (lastDividerRound != session.currentRound) {
        items.add(_buildRoundDivider(session.currentRound));
      }
    }
    
    return ListView(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      children: items,
    );
  }
}