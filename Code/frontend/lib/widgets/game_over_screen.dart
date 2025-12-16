import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../../../models/game_session.dart';
import '../utils/avatar_color_helper.dart';

import '../utils/audio_mixin.dart';
import '../utils/game_sounds.dart';
import 'dart:math' as math;

class GameOverScreen extends StatefulWidget {
  final GameSession session;
  final VoidCallback onBackToLobby;

  const GameOverScreen({
    Key? key,
    required this.session,
    required this.onBackToLobby,
  }) : super(key: key);

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with TickerProviderStateMixin, AudioMixin {
  late AnimationController _pillarController;
  late AnimationController _confettiController;
  late AnimationController _trophyController;
  late AnimationController _textController;
  late List<Confetti> _confettiPieces;

  @override
  void initState() {
    super.initState();
    _playGameOverAudio();

    _pillarController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _trophyController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Generate confetti pieces
    _confettiPieces = List.generate(50, (index) => Confetti.random());

    // Start animations sequentially
    _textController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _pillarController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _trophyController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _confettiController.forward();
    });
  }

  void _playGameOverAudio() async {
    // Stop game music and play game over music
    await stopBackgroundMusic();
    Future.delayed(const Duration(milliseconds: 300), () async {
      await playBackgroundMusic(GameSounds.gameOverMusic);
    });
  }

  @override
  void dispose() {
    _pillarController.dispose();
    _confettiController.dispose();
    _trophyController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = widget.session.players.sorted((a, b) => b.score.compareTo(a.score));

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade900, Colors.deepPurple.shade500],
          ),
        ),
        child: Stack(
          children: [
            // Confetti layer
            _buildConfetti(),

            // Main content
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAppBar(),
                    const SizedBox(height: 20),
                    _buildGameOverText(),
                    const SizedBox(height: 30),
                    _buildPodium(sortedPlayers),
                    const SizedBox(height: 30),
                    if (sortedPlayers.length > 3) _buildOtherPlayers(sortedPlayers),
                    const SizedBox(height: 24),
                    _buildBackButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: ConfettiPainter(
            confettiPieces: _confettiPieces,
            progress: _confettiController.value,
          ),
        );
      },
    );
  }

  Widget _buildGameOverText() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _textController,
          curve: Curves.elasticOut,
        ),
      ),
      child: Column(
        children: [
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
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _textController,
            builder: (context, child) {
              return Opacity(
                opacity: _textController.value,
                child: const Text(
                  '✨ Amazing game! ✨',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ],
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
            onPressed: _showExitConfirmation,
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

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit Game?'),
          content: const Text('Are you sure you want to return to the lobby?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Stop game over music and prepare to return to lobby
                _stopGameOverAndReturnToLobby();
              },
              child: const Text('Exit', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _stopGameOverAndReturnToLobby() async {
    // Stop game over music
    await stopBackgroundMusic();
    // Prepare lobby music to play
    await playBackgroundMusic(GameSounds.lobbyMusic);
    // Navigate back
    widget.onBackToLobby();
  }

  Future<bool> _onBackPressed() async {
    _showExitConfirmation();
    return false;
  }

  Widget _buildPodium(List<Player> players) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Second Place
        if (players.length > 1)
          _buildPodiumSpot(
            players[1],
            160,
            Colors.grey.shade300,
            '2nd',
            0.3,
          ),
        const SizedBox(width: 12),
        // First Place
        _buildPodiumSpot(
          players[0],
          200,
          Colors.amber,
          '1st',
          0.0,
        ),
        const SizedBox(width: 12),
        // Third Place
        if (players.length > 2)
          _buildPodiumSpot(
            players[2],
            120,
            Colors.brown.shade300,
            '3rd',
            0.6,
          ),
      ],
    );
  }

  Widget _buildPodiumSpot(
    Player player,
    double height,
    Color color,
    String place,
    double delay,
  ) {
    final avatarColor = AvatarColorHelper.getColorFromName(player.photoURL);
    final isFirst = place == '1st';

    return AnimatedBuilder(
      animation: _pillarController,
      builder: (context, child) {
        final progress = math.max(
          0.0,
          math.min(1.0, (_pillarController.value - delay) / (1 - delay)),
        );
        final curvedProgress = Curves.easeOutBack.transform(progress);

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Trophy for first place
            if (isFirst)
              ScaleTransition(
                scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _trophyController,
                    curve: Curves.elasticOut,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),

            // Avatar with bounce animation
            Transform.translate(
              offset: Offset(
                0,
                isFirst
                    ? -10 * math.sin(_trophyController.value * math.pi)
                    : 0,
              ),
              child: CircleAvatar(
                radius: isFirst ? 40 : 30,
                backgroundColor: avatarColor,
                child: Text(
                  player.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: isFirst ? 24 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              player.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: isFirst ? 18 : 16,
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

            // Animated pillar
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Container(
                width: 80,
                height: height * curvedProgress,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color,
                      color.withOpacity(0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Opacity(
                    opacity: progress,
                    child: Text(
                      place,
                      style: TextStyle(
                        color: isFirst ? Colors.black : Colors.black87,
                        fontSize: isFirst ? 24 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOtherPlayers(List<Player> sortedPlayers) {
    return FadeTransition(
      opacity: _pillarController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _pillarController,
          curve: Curves.easeOut,
        )),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
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
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return FadeTransition(
      opacity: _pillarController,
      child: ElevatedButton(
        onPressed: _showExitConfirmation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 8,
        ),
        child: const Text(
          'Back to Lobby',
          style: TextStyle(
            color: Colors.deepPurple,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Confetti data class
class Confetti {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double rotation;
  final double speed;

  Confetti({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.rotation,
    required this.speed,
  });

  factory Confetti.random() {
    final random = math.Random();
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.pink,
      Colors.purple,
      Colors.cyan,
    ];

    return Confetti(
      x: random.nextDouble(),
      y: -0.1,
      color: colors[random.nextInt(colors.length)],
      size: 8 + random.nextDouble() * 8,
      rotation: random.nextDouble() * math.pi * 2,
      speed: 0.3 + random.nextDouble() * 0.4,
    );
  }
}

// Confetti painter
class ConfettiPainter extends CustomPainter {
  final List<Confetti> confettiPieces;
  final double progress;

  ConfettiPainter({
    required this.confettiPieces,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var confetti in confettiPieces) {
      final paint = Paint()
        ..color = confetti.color.withOpacity(1 - progress * 0.5)
        ..style = PaintingStyle.fill;

      final x = confetti.x * size.width;
      final y = confetti.y * size.height + (size.height * progress * confetti.speed);
      final rotation = confetti.rotation + (progress * math.pi * 4);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: confetti.size,
          height: confetti.size,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}