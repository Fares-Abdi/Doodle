import 'package:flutter/material.dart';
import 'dart:async';
import '../models/game_session.dart';

class RoundCountdown extends StatefulWidget {
  final GameSession session;
  final String userId;
  final VoidCallback onCountdownComplete;

  const RoundCountdown({
    Key? key,
    required this.session,
    required this.userId,
    required this.onCountdownComplete,
  }) : super(key: key);

  @override
  State<RoundCountdown> createState() => _RoundCountdownState();
}

class _RoundCountdownState extends State<RoundCountdown>
    with TickerProviderStateMixin {
  late AnimationController _countdownController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  int _currentCount = 3;
  bool _showRole = false;

  @override
  void initState() {
    super.initState();
    _countdownController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _startCountdown();
  }

  void _startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentCount > 0) {
        _scaleController.forward(from: 0.0);
        _currentCount--;
        if (mounted) {
          setState(() {});
        }
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _showRole = true;
            _scaleController.forward(from: 0.0);
          });
        }
        // Show role for 2 seconds, then complete
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            widget.onCountdownComplete();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer = widget.session.players
        .firstWhere((p) => p.id == widget.userId);
    final isDrawer = currentPlayer.isDrawing;

    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Countdown numbers or Role display
            ScaleTransition(
              scale: _scaleAnimation,
              child: _showRole
                  ? _buildRoleDisplay(isDrawer)
                  : _buildCountdownNumber(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownNumber() {
    return Column(
      children: [
        Text(
          '$_currentCount',
          style: TextStyle(
            fontSize: 180,
            fontWeight: FontWeight.w900,
            color: _getCountdownColor(),
            shadows: [
              Shadow(
                blurRadius: 30,
                color: _getCountdownColor().withOpacity(0.8),
                offset: const Offset(0, 0),
              ),
              Shadow(
                blurRadius: 60,
                color: _getCountdownColor().withOpacity(0.4),
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'GET READY',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleDisplay(bool isDrawer) {
    final roleText = isDrawer ? 'YOU ARE\nDRAWING' : 'YOU ARE\nGUESSING';
    final roleColor = isDrawer
        ? Colors.orange.shade400
        : Colors.cyan;
    final roleIcon = isDrawer ? Icons.brush : Icons.lightbulb;

    return Column(
      children: [
        Icon(
          roleIcon,
          size: 100,
          color: roleColor,
          shadows: [
            Shadow(
              blurRadius: 30,
              color: roleColor.withOpacity(0.8),
              offset: const Offset(0, 0),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Text(
          roleText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w900,
            color: roleColor,
            height: 1.2,
            shadows: [
              Shadow(
                blurRadius: 25,
                color: roleColor.withOpacity(0.7),
                offset: const Offset(0, 0),
              ),
              Shadow(
                blurRadius: 50,
                color: roleColor.withOpacity(0.3),
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (isDrawer)
          Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'DRAW THIS WORD',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.session.currentWord ?? '???',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Colors.yellow.shade300,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      blurRadius: 30,
                      color: Colors.yellow.shade600.withOpacity(0.8),
                      offset: const Offset(0, 2),
                    ),
                    Shadow(
                      blurRadius: 50,
                      color: Colors.amber.withOpacity(0.4),
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.cyan,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Can you guess what\'s being drawn?',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Color _getCountdownColor() {
    switch (_currentCount) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.yellow;
      default:
        return Colors.white;
    }
  }
}
