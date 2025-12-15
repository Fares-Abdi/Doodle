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
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0x7B7B2D).withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(-10, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with players count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade500,
                      Colors.deepPurple.shade700,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Players Online',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Game in progress',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '${session.players.length} players',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Players list with Instagram-style design
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade100,
                      width: 1,
                    ),
                  ),
                ),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.2,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ...session.players.asMap().entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: entry.value.id == userId
                                ? LinearGradient(
                                    colors: [
                                      Colors.deepPurple.shade50,
                                      Colors.deepPurple.shade100.withOpacity(0.5),
                                    ],
                                  )
                                : null,
                            color: entry.value.id != userId ? Colors.grey.shade50 : null,
                            border: Border.all(
                              color: entry.value.id == userId
                                  ? Colors.deepPurple.shade300
                                  : Colors.grey.shade200,
                              width: entry.value.id == userId ? 1.5 : 1,
                            ),
                          ),
                          child: buildPlayerTile(entry.value),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              
              // Chat section
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: GameChat(
                    gameSession: session,
                    userId: userId,
                    userName: userName,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
