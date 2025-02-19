import 'package:flutter/material.dart';
import '../../../models/game_session.dart';
import '../../../widgets/game_chat.dart';

class ChatPanel extends StatelessWidget {
  final bool visible;
  final Animation<double> animation;
  final GameSession session;
  final String userId;
  final String userName;
  final Widget Function(Player) buildPlayerTile;

  const ChatPanel({
    Key? key,
    required this.visible,
    required this.animation,
    required this.session,
    required this.userId,
    required this.userName,
    required this.buildPlayerTile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation),
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildPlayersHeader(),
              _buildChatSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayersHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        border: Border(
          bottom: BorderSide(
            color: Colors.deepPurple.shade100,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Players',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          ...session.players.map((player) => buildPlayerTile(player)),
        ],
      ),
    );
  }

  Widget _buildChatSection() {
    return Expanded(
      child: GameChat(
        gameSession: session,
        userId: userId,
        userName: userName,
      ),
    );
  }
}
