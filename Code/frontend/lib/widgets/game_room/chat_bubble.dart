import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../utils/avatar_color_helper.dart';

class ChatBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isCurrentUser;
  final GameSession session;

  const ChatBubble({Key? key, required this.message, required this.isCurrentUser, required this.session}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final messageText = message['message'] as String? ?? '';
    final userId = message['userId'] as String? ?? '';
    final isCorrectGuess = message['isCorrectGuess'] ?? false;

    // Look up actual player data from session
    final player = session.players.firstWhere(
      (p) => p.id == userId,
      orElse: () => Player(id: userId, name: message['userName'] as String? ?? 'Unknown'),
    );
    final userName = player.name;
    
    // Get player's avatar color
    final avatarColorName = player.photoURL ?? 'blue';
    final playerColor = AvatarColorHelper.getColorFromName(avatarColorName);

    if (isCorrectGuess) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade500],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '🎉 $userName found the word!',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar for other users (left side)
            if (!isCurrentUser)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildAvatar(),
              ),
            
            // Message bubble
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [playerColor.withOpacity(0.8), playerColor],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      messageText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Avatar for current user (right side)
            if (isCurrentUser)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: _buildAvatar(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final userId = message['userId'] as String? ?? '';
    
    // Look up actual player data from session
    final player = session.players.firstWhere(
      (p) => p.id == userId,
      orElse: () => Player(id: userId, name: message['userName'] as String? ?? 'Unknown'),
    );
    final playerName = player.name;
    
    // Use the player's actual photoURL color (e.g., 'red', 'blue', 'purple')
    final avatarColorName = player.photoURL ?? 'blue';
    final avatarColor = AvatarColorHelper.getColorFromName(avatarColorName);
    
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: avatarColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrentUser 
            ? Colors.deepPurple.shade400 
            : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          playerName.isNotEmpty ? playerName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
