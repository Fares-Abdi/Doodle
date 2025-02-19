import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../../../models/game_session.dart';

class GameOverScreen extends StatelessWidget {
  final GameSession session;
  final VoidCallback onBackToLobby;

  const GameOverScreen({
    Key? key,
    required this.session,
    required this.onBackToLobby,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sort players by score
    final sortedPlayers = session.players.sorted((a, b) => b.score.compareTo(a.score));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.deepPurple.shade900, Colors.deepPurple.shade500],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAppBar(),
            const Text(
              'Game Over!',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildPodium(sortedPlayers),
            const SizedBox(height: 40),
            if (sortedPlayers.length > 3) _buildOtherPlayers(sortedPlayers),
            const SizedBox(height: 32),
            _buildBackButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBackToLobby,
          ),
          const Text(
            'Srible Game',
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

  Widget _buildPodium(List<Player> players) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Second Place
            if (players.length > 1) _buildPodiumSpot(
              players[1],
              160,
              Colors.grey.shade300,
              '2nd',
            ),
            const SizedBox(width: 12),
            // First Place
            _buildPodiumSpot(
              players[0],
              200,
              Colors.amber,
              '1st',
            ),
            const SizedBox(width: 12),
            // Third Place
            if (players.length > 2) _buildPodiumSpot(
              players[2],
              120,
              Colors.brown.shade300,
              '3rd',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPodiumSpot(Player player, double height, Color color, String place) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: place == '1st' ? 40 : 30,
          backgroundImage: player.photoURL != null ? NetworkImage(player.photoURL!) : null,
          backgroundColor: Colors.white,
          child: player.photoURL == null
              ? Text(
                  player.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: place == '1st' ? 24 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          player.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: place == '1st' ? 18 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${player.score} pts',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              place,
              style: TextStyle(
                color: place == '1st' ? Colors.black : Colors.black87,
                fontSize: place == '1st' ? 24 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherPlayers(List<Player> sortedPlayers) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: sortedPlayers
            .skip(3)
            .map((player) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${sortedPlayers.indexOf(player) + 1}. ',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${player.name}: ${player.score}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ))
            .toList(),
      ),
    );
  }

  Widget _buildBackButton() {
    return ElevatedButton(
      onPressed: onBackToLobby,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: const Text(
        'Back to Lobby',
        style: TextStyle(
          color: Colors.deepPurple,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
