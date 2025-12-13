import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../utils/avatar_color_helper.dart';


class RoundTransition extends StatelessWidget {
  final GameSession session;

  const RoundTransition({
    Key? key,
    required this.session,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {


    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.fromARGB(255, 39, 28, 85), Color.fromARGB(255, 96, 30, 144)],
        ),
      ),
      child: Center(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Round Complete!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Next round starting soon...',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: value,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                        strokeWidth: 8,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildPlayerGrid(context),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlayerGrid(BuildContext context) {
    // Find the next drawer
    final currentDrawerIndex = session.players.indexWhere((p) => p.isDrawing);
    final nextDrawerIndex = (currentDrawerIndex + 1) % session.players.length;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: session.players.map((player) {
        final isNextDrawer = session.players.indexOf(player) == nextDrawerIndex;
        final avatarColor = AvatarColorHelper.getColorFromName(player.photoURL);
        
        return Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: isNextDrawer ? 35 : 30,
                  backgroundColor: avatarColor,
                  child: Text(
                    player.name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: isNextDrawer ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (isNextDrawer)
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
                fontWeight: isNextDrawer ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              '${player.score} pts',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
