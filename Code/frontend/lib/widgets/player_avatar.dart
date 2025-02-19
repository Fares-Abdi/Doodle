import 'package:flutter/material.dart';
import '../../../models/game_session.dart';

class PlayerAvatar extends StatelessWidget {
  final Player player;
  final bool isCurrentUser;
  final bool isNewPlayer;
  final VoidCallback? onAnimationEnd;

  const PlayerAvatar({
    Key? key,
    required this.player,
    this.isCurrentUser = false,
    this.isNewPlayer = false,
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
      onEnd: onAnimationEnd,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value.clamp(0.0, 1.0),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: isCurrentUser ? 40 : 30,
                  backgroundImage: player.photoURL != null ? NetworkImage(player.photoURL!) : null,
                  backgroundColor: Colors.white,
                  child: player.photoURL == null 
                      ? Text(
                          player.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: isCurrentUser ? 24 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ) 
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  player.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
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
