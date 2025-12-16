import 'package:flutter/material.dart';
import 'dart:async';
import '../models/game_session.dart';
import '../utils/audio_mixin.dart';
import '../utils/game_sounds.dart';
import 'advanced_drawing_canvas.dart';
import 'round_countdown.dart';

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

class _GameBoardState extends State<GameBoard> with AudioMixin {
  late StreamController<int> _timerController;
  Timer? _timer;
  bool _roundEnded = false;
  bool _showCountdown = true;
  static const int ROUND_DURATION = 80; // seconds

  @override
  void initState() {
    super.initState();
    _timerController = StreamController<int>.broadcast();
    _playRoundStart();
    _startTimer();
  }

  void _playRoundStart() async {
    await playRoundStart();
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
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
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

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade50, Colors.purple.shade50],
            ),
          ),
          child: Column(
            children: [
              // Top info bar
              _buildGameHeader(currentPlayer),
              // Canvas area
              Expanded(
                child: _buildDrawingCanvas(),
              ),
            ],
          ),
        ),
        // Countdown overlay
        if (_showCountdown)
          RoundCountdown(
            session: widget.session,
            userId: widget.userId,
            onCountdownComplete: () {
              if (mounted) {
                setState(() {
                  _showCountdown = false;
                });
              }
            },
          ),
      ],
    );
  }

  Widget _buildGameHeader(Player currentPlayer) {
    final isDrawer = currentPlayer.isDrawing;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade700,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Round info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Round ${widget.session.currentRound}/${widget.session.maxRounds}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Only show word to drawer
              if (isDrawer)
                Text(
                  widget.session.currentWord ?? '???',
                  style: TextStyle(
                    color: Colors.yellow.shade300,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                )
              else
                Text(
                  'Guess the drawing!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          // Timer - prominently displayed
          _buildTimerWidget(),
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Your Score',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                '${currentPlayer.score}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerWidget() {
    return StreamBuilder<int>(
      stream: _timerController.stream,
      initialData: DateTime.now().millisecondsSinceEpoch,
      builder: (context, snapshot) {
        if (widget.session.roundStartTime == null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '--s',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        // Calculate remaining time
        final now = DateTime.now();
        final elapsedMs = now.difference(widget.session.roundStartTime!).inMilliseconds;
        final totalRoundMs = ROUND_DURATION * 1000;
        final remainingMs = totalRoundMs - elapsedMs;
        final remaining = remainingMs > 0 ? (remainingMs / 1000).ceil() : 0;

        // End round when timer reaches zero
        if (remaining <= 0 && widget.session.state == GameState.drawing && !_roundEnded) {
          _roundEnded = true;
          Future.microtask(() => widget.onEndRound());
        }

        // Color changes based on time remaining
        Color timerColor = Colors.white;
        if (remaining < 10) {
          timerColor = Colors.red.shade300;
        } else if (remaining < 20) {
          timerColor = Colors.orange.shade300;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: timerColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: timerColor, width: 2),
          ),
          child: Text(
            '${remaining}s',
            style: TextStyle(
              color: timerColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawingCanvas() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
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
    );
  }
}
