import 'package:flutter/material.dart';
import '../models/game_session.dart';
import 'dart:math';

class EnhancedLeaderboard extends StatefulWidget {
  final GameSession session;
  final String userId;

  const EnhancedLeaderboard({
    Key? key,
    required this.session,
    required this.userId,
  }) : super(key: key);

  @override
  State<EnhancedLeaderboard> createState() => _EnhancedLeaderboardState();
}

class _EnhancedLeaderboardState extends State<EnhancedLeaderboard>
    with TickerProviderStateMixin {
  late AnimationController _sparkleController;
  late List<AnimationController> _entryControllers;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _entryControllers = List.generate(
      widget.session.players.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 100)),
        vsync: this,
      )..forward(),
    );
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    for (var controller in _entryControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFD8B4FE),
            const Color(0xFFC4B5FD).withOpacity(0.9),
            const Color(0xFFA78BFA).withOpacity(0.85),
          ],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            children: _buildLeaderboard(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLeaderboard(BuildContext context) {
    final sortedPlayers = List<Player>.from(widget.session.players)
      ..sort((a, b) => b.score.compareTo(a.score));

    return sortedPlayers.asMap().entries.map((entry) {
      final index = entry.key;
      final player = entry.value;
      final isCurrentUser = player.id == widget.userId;
      final medalType = index == 0 ? 'gold' : index == 1 ? 'silver' : index == 2 ? 'bronze' : null;

      return FadeTransition(
        opacity: _entryControllers[index],
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _entryControllers[index],
            curve: Curves.easeOutCubic,
          )),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Sparkle effect for gold medal
                if (medalType == 'gold')
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _sparkleController,
                      builder: (context, child) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Animated glow effect - enhanced
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withOpacity(
                                      0.7 + (sin(_sparkleController.value * pi * 2) * 0.3),
                                    ),
                                    blurRadius: 30 + (sin(_sparkleController.value * pi * 2) * 15).abs(),
                                    spreadRadius: 6,
                                    offset: const Offset(0, -15),
                                  ),
                                ],
                              ),
                            ),
                            // Sparkle particles - enhanced
                            CustomPaint(
                              painter: SparklePainter(
                                animation: _sparkleController,
                                color: const Color(0xFFFFD700),
                              ),
                              size: const Size(250, 150),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                // Main card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: _getMetallicGradient(medalType),
                    boxShadow: [
                      BoxShadow(
                        color: _getMedalColor(medalType).withOpacity(medalType != null ? 0.4 : 0.15),
                        blurRadius: medalType == 'gold' ? 12 : 8,
                        offset: const Offset(0, 4),
                        spreadRadius: medalType == 'gold' ? 1 : 0,
                      ),
                      if (medalType == 'gold')
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(
                            0.7 + (sin(_sparkleController.value * pi * 2) * 0.3),
                          ),
                          blurRadius: 35 + (sin(_sparkleController.value * pi * 2) * 10).abs(),
                          offset: const Offset(0, 0),
                          spreadRadius: 4,
                        ),
                    ],
                    border: Border.all(
                      color: isCurrentUser
                          ? Colors.deepPurple.shade300
                          : _getMedalColor(medalType).withOpacity(medalType != null ? 0.5 : 0.3),
                      width: isCurrentUser ? 2.5 : (medalType != null ? 1.5 : 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Medal badge with crown overlay for gold
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.deepPurple.shade300,
                                  Colors.deepPurple.shade500,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                player.isDrawing ? Icons.brush : Icons.lightbulb_outline,
                                size: 24,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Player info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    player.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isCurrentUser
                                          ? Colors.deepPurple.shade700
                                          : medalType != null
                                              ? Colors.grey.shade900
                                              : Colors.grey.shade800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (medalType == 'gold')
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Icon(
                                      Icons.auto_awesome,
                                      size: 14,
                                      color: const Color(0xFFFFED4E),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                          ],
                        ),
                      ),

                      // Score badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? Colors.deepPurple.shade100
                              : medalType != null
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrentUser
                                ? Colors.deepPurple.shade300
                                : medalType != null
                                    ? Colors.white.withOpacity(0.5)
                                    : Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${player.score}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isCurrentUser
                                ? Colors.deepPurple.shade700
                                : medalType != null
                                    ? Colors.white
                                    : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  LinearGradient _getMetallicGradient(String? medalType) {
    switch (medalType) {
      case 'gold':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD700),
            Color(0xFFFFA500),
            Color(0xFFFF8C00),
          ],
          stops: [0.0, 0.5, 1.0],
        );
      case 'silver':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF5F5F5),
            Color(0xFFE8E8E8),
            Color(0xFFC0C0C0),
          ],
        );
      case 'bronze':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFCD7F32),
            Color(0xFFB87333),
            Color(0xFFA0826D),
          ],
        );
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade50,
            Colors.grey.shade100,
          ],
        );
    }
  }

  Color _getMedalColor(String? medalType) {
    switch (medalType) {
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'bronze':
        return const Color(0xFFCD7F32);
      default:
        return Colors.grey;
    }
  }

  List<Color> _getMedalGradient(String medalType) {
    switch (medalType) {
      case 'gold':
        return const [
          Color(0xFFFFED4E),
          Color(0xFFFFD700),
          Color(0xFFFFA500),
        ];
      case 'silver':
        return const [
          Color(0xFFF5F5F5),
          Color(0xFFE8E8E8),
          Color(0xFFC0C0C0),
        ];
      case 'bronze':
        return const [
          Color(0xFFE8A76F),
          Color(0xFFCD7F32),
          Color(0xFFA0826D),
        ];
      default:
        return [Colors.grey.shade300, Colors.grey.shade400];
    }
  }

  IconData _getMedalIcon(String medalType) {
    switch (medalType) {
      case 'gold':
        return Icons.workspace_premium;
      case 'silver':
        return Icons.military_tech;
      case 'bronze':
        return Icons.emoji_events;
      default:
        return Icons.star;
    }
  }
}

class SparklePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  SparklePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // More sparkles for better effect
    final sparkles = [
      _Sparkle(size.width * 0.15, size.height * 0.2, 3, 0.0),
      _Sparkle(size.width * 0.85, size.height * 0.15, 2.5, 0.15),
      _Sparkle(size.width * 0.2, size.height * 0.75, 2, 0.3),
      _Sparkle(size.width * 0.9, size.height * 0.8, 3.5, 0.45),
      _Sparkle(size.width * 0.5, size.height * 0.1, 2.5, 0.1),
      _Sparkle(size.width * 0.75, size.height * 0.85, 2.5, 0.35),
      _Sparkle(size.width * 0.05, size.height * 0.5, 2, 0.25),
      _Sparkle(size.width * 0.95, size.height * 0.5, 2, 0.5),
    ];

    for (var sparkle in sparkles) {
      final progress = ((animation.value + sparkle.delay) % 1.0);
      final opacity = (progress < 0.5 ? progress * 2 : (1 - progress) * 2).clamp(0.0, 1.0);
      
      paint.color = color.withOpacity(opacity * 0.7);
      
      // Draw 4-pointed star sparkle
      final path = Path();
      final centerX = sparkle.x;
      final centerY = sparkle.y;
      final size = sparkle.size * (0.6 + opacity * 0.6);
      
      // Create a 4-pointed star
      for (int i = 0; i < 4; i++) {
        final angle = (i * 90.0) * (3.14159 / 180.0);
        final outerRadius = size * 2.5;
        final x = centerX + outerRadius * cos(angle);
        final y = centerY + outerRadius * sin(angle);
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        
        // Inner point of star
        final innerAngle = ((i * 90.0) + 45.0) * (3.14159 / 180.0);
        final innerRadius = size * 0.8;
        final innerX = centerX + innerRadius * cos(innerAngle);
        final innerY = centerY + innerRadius * sin(innerAngle);
        path.lineTo(innerX, innerY);
      }
      
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  double cos(double radians) => radians.cos();
  double sin(double radians) => radians.sin();

  @override
  bool shouldRepaint(SparklePainter oldDelegate) => true;
}

class _Sparkle {
  final double x;
  final double y;
  final double size;
  final double delay;

  _Sparkle(this.x, this.y, this.size, this.delay);
}

extension on double {
  double cos() {
    return (this * 180 / 3.14159).cosineValue();
  }
  
  double sin() {
    return (this * 180 / 3.14159).sineValue();
  }
  
  double cosineValue() {
    // Approximation using Taylor series
    final x = this % 360;
    final rad = x * 3.14159 / 180;
    return 1 - (rad * rad) / 2 + (rad * rad * rad * rad) / 24 - (rad * rad * rad * rad * rad * rad) / 720;
  }
  
  double sineValue() {
    final x = this % 360;
    final rad = x * 3.14159 / 180;
    return rad - (rad * rad * rad) / 6 + (rad * rad * rad * rad * rad) / 120 - (rad * rad * rad * rad * rad * rad * rad) / 5040;
  }
}
