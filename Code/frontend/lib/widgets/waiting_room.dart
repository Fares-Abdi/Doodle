import 'package:flutter/material.dart';
import '../../../models/game_session.dart';
import 'player_avatar.dart';

class WaitingRoom extends StatelessWidget {
  final GameSession session;
  final String userId;
  final Set<String> animatedPlayers;
  final VoidCallback onStartGame;
  final VoidCallback onBack;

  const WaitingRoom({
    Key? key,
    required this.session,
    required this.userId,
    required this.animatedPlayers,
    required this.onStartGame,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.fromARGB(255, 39, 28, 85), Color.fromARGB(255, 96, 30, 144)],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              // Custom App Bar for waiting room
              _buildAppBar(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPlayersCountText(),
                      const SizedBox(height: 40),
                      _buildPlayerAvatars(),
                      const SizedBox(height: 48),
                      _buildStartButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBack,
          ),
          const Text(
            'Waiting Room',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersCountText() {
    return Text(
      '${session.players.length} players are in the waiting room',
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white
      ),
    );
  }

  Widget _buildPlayerAvatars() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 24,
      runSpacing: 24,
      children: session.players.map((player) {
        final isNewPlayer = !animatedPlayers.contains(player.id);
        return PlayerAvatar(
          player: player,
          isCurrentUser: player.id == userId,
          isNewPlayer: isNewPlayer,
          onAnimationEnd: () {
            animatedPlayers.add(player.id);
          },
        );
      }).toList(),
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton(
      onPressed: session.players.length >= 2 ? onStartGame : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        disabledBackgroundColor: Colors.white.withOpacity(0.3),
        disabledForegroundColor: Colors.white.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(
          horizontal: 48,
          vertical: 16
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)
        ),
      ),
      child: Text(
        session.players.length >= 2 ? 'START GAME' : 'WAITING FOR PLAYERS',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
