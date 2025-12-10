import 'package:flutter/material.dart';
import 'dart:async';
import '../models/game_session.dart';
import 'advanced_drawing_canvas.dart';

class GameBoard extends StatefulWidget {
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
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  late StreamController<int> _timerController;
  Timer? _timer;
  bool _roundEnded = false;

  @override
  void initState() {
    super.initState();
    _timerController = StreamController<int>.broadcast();
    _startTimer();
  }

  @override
  void didUpdateWidget(GameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset the round ended flag when the session changes
    if (oldWidget.session.state != widget.session.state) {
      _roundEnded = false;
    }
    // Restart timer if the round start time changed
    if (oldWidget.session.roundStartTime != widget.session.roundStartTime) {
      _timer?.cancel();
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        _timerController.add(DateTime.now().millisecondsSinceEpoch);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer = widget.session.players.firstWhere((p) => p.id == widget.userId);

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
          Text('Round ${widget.session.currentRound}/${widget.session.maxRounds}'),
          if (widget.session.roundStartTime != null) _buildTimer(),
          Text('Score: ${currentPlayer.score}'),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    return StreamBuilder<int>(
      stream: _timerController.stream,
      builder: (context, snapshot) {
        if (widget.session.roundStartTime == null) {
          return const Text('Time: --s');
        }

        // Calculate elapsed time
        // Use server time from the last update if available, otherwise client time
        final now = DateTime.now();
        final elapsedMs = now.difference(widget.session.roundStartTime!).inMilliseconds;
        
        final totalRoundMs = widget.session.roundTime * 1000; // Convert to milliseconds
        final remainingMs = totalRoundMs - elapsedMs;
        
        // Ensure remaining is never negative (show 0 at minimum)
        final remaining = remainingMs > 0 ? (remainingMs / 1000).ceil() : 0;
        
        // Debug logging
        if (snapshot.hasData && remaining > 0) {
          print('Timer - Elapsed: ${elapsedMs}ms, Total: ${totalRoundMs}ms, Remaining: ${remaining}s');
        }
        
        // End round when timer reaches zero, but only once
        if (remaining <= 0 && widget.session.state == GameState.drawing && !_roundEnded) {
          _roundEnded = true;
          print('Timer expired, ending round');
          Future.microtask(() => widget.onEndRound());
        }

        return Text(
          'Time: ${remaining}s',
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
                userId: widget.userId,
                gameSession: widget.session,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
