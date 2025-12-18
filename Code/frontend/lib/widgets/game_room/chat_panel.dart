import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../enhanced_leaderboard.dart';
import 'chat_header.dart';
import 'chat_messages_list.dart';
import 'message_input.dart';

class ChatPanel extends StatelessWidget {
  final GameSession session;
  final String userId;
  final List<Map<String, dynamic>> messages;
  final ScrollController scrollController;
  final TextEditingController chatController;
  final void Function(String) onSend;
  final int playerCount;
  final double leaderboardHeight;
  final Widget dividerWidget;

  const ChatPanel({
    Key? key,
    required this.session,
    required this.userId,
    required this.messages,
    required this.scrollController,
    required this.chatController,
    required this.onSend,
    required this.playerCount,
    required this.leaderboardHeight,
    required this.dividerWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      color: Colors.white,
      child: Column(
        children: [
          ChatHeader(playerCount: playerCount),

          // Leaderboard
          Container(
            height: leaderboardHeight,
            clipBehavior: Clip.none,
            child: EnhancedLeaderboard(
              session: session,
              userId: userId,
            ),
          ),

          // Divider (passed in from parent so it can hold state/animations)
          dividerWidget,

          // Chat messages area (Expanded)
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: ChatMessagesList(messages: messages, controller: scrollController, userId: userId, session: session),
            ),
          ),

          // Message input - fixed at bottom of panel
          MessageInput(controller: chatController, onSend: onSend),
        ],
      ),
    );
  }
}
