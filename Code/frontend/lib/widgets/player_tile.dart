import 'package:flutter/material.dart';
import '../models/game_session.dart';

class PlayerAvatar extends StatelessWidget {
  final Player player;
  final bool isNewPlayer;
  final bool isHighlighted;
  final double baseRadius;
  final Set<String> animatedPlayers;
  final Function(String)? onAnimationEnd;

  const PlayerAvatar({
    Key? key,
    required this.player,
    this.isNewPlayer = false,
    this.isHighlighted = false,
    this.baseRadius = 30,
    required this.animatedPlayers,
    this.onAnimationEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      tween: Tween<double>(
        begin: isNewPlayer ? 0.0 : 1.0,
        end: 1.0,
      ),
      onEnd: () {
        if (onAnimationEnd != null) {
          onAnimationEnd!(player.id);
        }
      },
      builder: (context, value, child) {
        return Transform.scale(
          scale: value.clamp(0.0, 1.0),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: isHighlighted ? baseRadius + 10 : baseRadius,
                      backgroundImage: player.photoURL != null ? NetworkImage(player.photoURL!) : null,
                      backgroundColor: Colors.white,
                      child: player.photoURL == null ? Text(
                        player.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: isHighlighted ? 24 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ) : null,
                    ),
                    if (player.isDrawing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.brush,
                            color: Colors.deepPurple,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  player.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                if (isHighlighted)
                  Text(
                    '${player.score} pts',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PlayerTile extends StatelessWidget {
  final Player player;
  final bool isHighlighted;

  const PlayerTile({
    Key? key,
    required this.player,
    this.isHighlighted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: player.isDrawing ? Colors.deepPurple.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: player.isDrawing ? [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 1,
          )
        ] : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (player.isDrawing)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.brush, color: Colors.deepPurple, size: 16),
                ),
              CircleAvatar(
                radius: 16,
                backgroundImage: player.photoURL != null ? NetworkImage(player.photoURL!) : null,
                backgroundColor: Colors.deepPurple.shade50,
                child: player.photoURL == null 
                    ? Text(
                        player.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ) 
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                player.name,
                style: TextStyle(
                  color: player.isDrawing ? Colors.deepPurple : Colors.black87,
                  fontWeight: player.isDrawing ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          Text(
            player.score.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
}