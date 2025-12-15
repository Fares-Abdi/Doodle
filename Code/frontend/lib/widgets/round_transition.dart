import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../utils/avatar_color_helper.dart';
import '../utils/audio_mixin.dart';
import '../utils/game_sounds.dart';
import 'dart:math' as math;

class RoundTransition extends StatefulWidget {
  final GameSession session;

  const RoundTransition({
    Key? key,
    required this.session,
  }) : super(key: key);

  @override
  State<RoundTransition> createState() => _RoundTransitionState();
}

class _RoundTransitionState extends State<RoundTransition>
    with TickerProviderStateMixin, AudioMixin {
  late AnimationController _drawController;
  late AnimationController _fadeController;
  late AnimationController _pencilController;

  @override
  void initState() {
    super.initState();
    _playRoundTransitionAudio();
    
    _drawController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pencilController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _drawController.forward();
    _fadeController.forward();
    _pencilController.forward();
  }

  void _playRoundTransitionAudio() async {
    await getAudioService().playSfx(GameSounds.roundTransitionMusic);
  }

  @override
  void dispose() {
    _drawController.dispose();
    _fadeController.dispose();
    _pencilController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentDrawerIndex = widget.session.players.indexWhere((p) => p.isDrawing);
    final nextDrawerIndex = (currentDrawerIndex + 1) % widget.session.players.length;
    final nextDrawer = widget.session.players[nextDrawerIndex];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 39, 28, 85),
            Color.fromARGB(255, 96, 30, 144)
          ],
        ),
      ),
      child: Stack(
        children: [
          // Floating pencil animation
          _buildFloatingPencils(),
          
          // Main content
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Animated checkmark with drawing effect
                  _buildAnimatedCheck(),
                  
                  const SizedBox(height: 32),
                  
                  // "Round Complete" with fade-in
                  FadeTransition(
                    opacity: _fadeController,
                    child: const Text(
                      'Round Complete!',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Next drawer announcement with sketch effect
                  _buildNextDrawerCard(nextDrawer),
                  
                  const SizedBox(height: 40),
                  
                  // Player grid
                  _buildPlayerGrid(context, nextDrawerIndex),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingPencils() {
    return AnimatedBuilder(
      animation: _pencilController,
      builder: (context, child) {
        return Stack(
          children: List.generate(6, (index) {
            final delay = index * 0.15;
            final progress = math.max(0.0, (_pencilController.value - delay) / (1 - delay));
            final angle = (index * 60.0) * math.pi / 180;
            final distance = 150.0 * progress;
            
            return Positioned(
              left: MediaQuery.of(context).size.width / 2 + math.cos(angle) * distance - 15,
              top: MediaQuery.of(context).size.height / 2 + math.sin(angle) * distance - 15,
              child: Opacity(
                opacity: (1 - progress) * 0.3,
                child: Transform.rotate(
                  angle: angle + math.pi / 4,
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildAnimatedCheck() {
    return AnimatedBuilder(
      animation: _drawController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(120, 120),
          painter: CheckMarkPainter(
            progress: _drawController.value,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildNextDrawerCard(dynamic nextDrawer) {
    final avatarColor = AvatarColorHelper.getColorFromName(nextDrawer.photoURL);
    
    return ScaleTransition(
      scale: Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Curves.elasticOut,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Next Artist',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                // Animated circles
                AnimatedBuilder(
                  animation: _drawController,
                  builder: (context, child) {
                    return Container(
                      width: 100 + (20 * math.sin(_drawController.value * math.pi)),
                      height: 100 + (20 * math.sin(_drawController.value * math.pi)),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                    );
                  },
                ),
                // Avatar
                CircleAvatar(
                  radius: 45,
                  backgroundColor: avatarColor,
                  child: Text(
                    nextDrawer.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Brush icon
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.brush,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              nextDrawer.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${nextDrawer.score} points',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerGrid(BuildContext context, int nextDrawerIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: widget.session.players.asMap().entries.map((entry) {
          final index = entry.key;
          final player = entry.value;
          final isNextDrawer = index == nextDrawerIndex;
          final avatarColor = AvatarColorHelper.getColorFromName(player.photoURL);
          
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: isNextDrawer ? 0.5 : 1.0,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: avatarColor,
                  child: Text(
                    player.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  player.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CheckMarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  CheckMarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final circlePaint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    // Draw circle
    final circleProgress = math.min(1.0, progress * 1.5);
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2 - 10,
      ),
      -math.pi / 2,
      2 * math.pi * circleProgress,
      false,
      circlePaint,
    );

    // Draw checkmark
    if (progress > 0.4) {
      final checkProgress = (progress - 0.4) / 0.6;
      final path = Path();
      
      final p1 = Offset(size.width * 0.3, size.height * 0.5);
      final p2 = Offset(size.width * 0.45, size.height * 0.65);
      final p3 = Offset(size.width * 0.7, size.height * 0.35);

      path.moveTo(p1.dx, p1.dy);
      
      if (checkProgress < 0.5) {
        final t = checkProgress * 2;
        path.lineTo(
          p1.dx + (p2.dx - p1.dx) * t,
          p1.dy + (p2.dy - p1.dy) * t,
        );
      } else {
        path.lineTo(p2.dx, p2.dy);
        final t = (checkProgress - 0.5) * 2;
        path.lineTo(
          p2.dx + (p3.dx - p2.dx) * t,
          p2.dy + (p3.dy - p2.dy) * t,
        );
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CheckMarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}