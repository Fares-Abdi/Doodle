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
              
              // Leaderboard with metallic medal podium
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.35,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    child: Column(
                      children: [
                        ..._buildLeaderboard(context),
                      ],
                    ),
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

  List<Widget> _buildLeaderboard(BuildContext context) {
    // Sort players by score in descending order
    final sortedPlayers = List<Player>.from(session.players)
      ..sort((a, b) => b.score.compareTo(a.score));

    return sortedPlayers.asMap().entries.map((entry) {
      final index = entry.key;
      final player = entry.value;
      final isCurrentUser = player.id == userId;
      
      // Determine medal type
      final medalType = index == 0 ? 'gold' : index == 1 ? 'silver' : index == 2 ? 'bronze' : null;
      
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Stack(
          children: [
            // Metallic card background
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: _getMetallicGradient(medalType),
                boxShadow: [
                  BoxShadow(
                    color: _getMedalColor(medalType).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isCurrentUser
                      ? Colors.deepPurple.shade300
                      : _getMedalColor(medalType).withOpacity(0.4),
                  width: isCurrentUser ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Medal badge
                  if (medalType != null)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _getMedalGradient(medalType),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getMedalColor(medalType).withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getMedalEmoji(medalType),
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade300,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  
                  // Player info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isCurrentUser
                                ? Colors.deepPurple.shade700
                                : Colors.grey.shade900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          player.isDrawing ? '🎨 Drawing' : 'Guessing',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Score badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? Colors.deepPurple.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrentUser
                            ? Colors.deepPurple.shade300
                            : Colors.grey.shade400,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${player.score} pts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isCurrentUser
                            ? Colors.deepPurple.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  LinearGradient _getMetallicGradient(String? medalType) {
    switch (medalType) {
      case 'gold':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD700),
            Color(0xFFFFA500),
            Color(0xFFFF8C00),
          ],
        );
      case 'silver':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFC0C0C0),
            Color(0xFFE8E8E8),
            Color(0xFFA9A9A9),
          ],
        );
      case 'bronze':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFCD7F32),
            Color(0xFFB87333),
            Color(0xFFA0826D),
          ],
        );
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
        );
    }
  }

  Color _getMedalColor(String? medalType) {
    switch (medalType) {
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'bronze':
        return const Color(0xFFCD7F32);
      default:
        return Colors.grey;
    }
  }

  List<Color> _getMedalGradient(String medalType) {
    switch (medalType) {
      case 'gold':
        return [
          Color(0xFFFFED4E),
          Color(0xFFFFD700),
          Color(0xFFFFA500),
        ];
      case 'silver':
        return [
          Color(0xFFF5F5F5),
          Color(0xFFE8E8E8),
          Color(0xFFC0C0C0),
        ];
      case 'bronze':
        return [
          Color(0xFFE8A76F),
          Color(0xFFCD7F32),
          Color(0xFFA0826D),
        ];
      default:
        return [Colors.grey.shade300, Colors.grey.shade400];
    }
  }

  String _getMedalEmoji(String medalType) {
    switch (medalType) {
      case 'gold':
        return '🥇';
      case 'silver':
        return '🥈';
      case 'bronze':
        return '🥉';
      default:
        return '🎖️';
    }
  }
}
