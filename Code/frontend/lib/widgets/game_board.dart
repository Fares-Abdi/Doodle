import 'package:flutter/material.dart';
import '../../../models/game_session.dart';
import '../../../widgets/advanced_drawing_canvas.dart';

class GameBoard extends StatelessWidget {
  final GameSession session;
  final String userId;
  final VoidCallback onEndRound;

  const GameBoard({
    Key? key,
    required this.session,
    required this.userId,
    required this.onEndRound,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentPlayer = session.players.firstWhere((p) => p.id == userId);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.purple.shade50],
        ),
      ),
      child: Column(
        children: [
          _buildGameHeader(currentPlayer),
          Expanded(
            child: _buildDrawingCanvas(),
          ),
        ],
      ),
    );
  }

  Widget _buildGameHeader(Player currentPlayer) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Round ${session.currentRound + 1}/${session.maxRounds}'),
          if (session.roundStartTime != null) _buildTimer(),
          Text('Score: ${currentPlayer.score}'),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final remaining = session.roundTime -
            DateTime.now()
                .difference(session.roundStartTime!)
                .inSeconds;
        
        // End round when timer reaches zero
        if (remaining <= 0 && session.state == GameState.drawing) {
          onEndRound();
        }

        return Text(
          'Time: ${remaining > 0 ? remaining : 0}s',
          style: TextStyle(
            color: remaining < 10 ? Colors.red : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }

  Widget _buildDrawingCanvas() {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AdvancedDrawingCanvas(
                userId: userId,
                gameSession: session,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
