import 'package:flutter/material.dart';
import '../models/game_session.dart';
import 'game_chat.dart';

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
          width: MediaQuery.of(context).size.width * 0.75,
          constraints: const BoxConstraints(maxWidth: 350),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 3,
                offset: const Offset(-3, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with players count
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade600,
                      Colors.deepPurple.shade700,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Players',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${session.players.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Players list
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ...session.players.map((player) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: buildPlayerTile(player),
                      )),
                    ],
                  ),
                ),
              ),
              
              // Chat section
              Expanded(
                child: GameChat(
                  gameSession: session,
                  userId: userId,
                  userName: userName,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
