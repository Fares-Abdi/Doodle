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
    // Check if current user is the drawer
    final currentPlayer = session.players.firstWhere(
      (p) => p.id == userId,
      orElse: () => Player(id: userId, name: 'Player'),
    );
    final isDrawer = currentPlayer.isDrawing;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Enhanced header
          ChatHeader(playerCount: playerCount),

          // Leaderboard section
          Container(
            height: leaderboardHeight,
            clipBehavior: Clip.none,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey.shade50,
                  Colors.white,
                ],
              ),
            ),
            child: EnhancedLeaderboard(
              session: session,
              userId: userId,
            ),
          ),

          // Enhanced divider
          dividerWidget,

          // Chat messages area with gradient background
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey.shade50,
                    Colors.grey.shade100,
                  ],
                ),
              ),
              child: ChatMessagesList(
                messages: messages,
                controller: scrollController,
                userId: userId,
                session: session,
              ),
            ),
          ),

          // Enhanced message input
          MessageInput(
            controller: chatController,
            onSend: onSend,
            isDrawer: isDrawer,
          ),
        ],
      ),
    );
  }
}