import 'package:flutter/material.dart';
import '../models/game_session.dart';
import 'game_chat.dart';
import 'enhanced_leaderboard.dart';

class ChatPanel extends StatefulWidget {
  final bool visible;
  final Animation<double> animation;
  final GameSession session;
  final String userId;
  final String userName;
  final Widget Function(Player) buildPlayerTile;

  const ChatPanel({
    Key? key,
    required this.visible,
    required this.animation,
    required this.session,
    required this.userId,
    required this.userName,
    required this.buildPlayerTile,
  }) : super(key: key);

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  double _leaderboardHeight = 0.38; // 38% by default - shows full gold medal position
  late double _panelContentHeight;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Responsive width: 85% on small screens, 75% on larger
    final panelWidth = screenWidth < 400 
        ? screenWidth * 0.85 
        : screenWidth * 0.75;

    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(widget.animation),
        child: Container(
          width: panelWidth,
          constraints: BoxConstraints(
            maxWidth: 420,
            minWidth: 280,
          ),
          clipBehavior: Clip.none,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(-8, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with players count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade500,
                      Colors.deepPurple.shade700,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Players Online',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Game in progress',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.75),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.35),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${widget.session.players.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Leaderboard with sparkle overflow effect
              Container(
                height: _getLeaderboardHeight(context),
                clipBehavior: Clip.none,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    EnhancedLeaderboard(
                      session: widget.session,
                      userId: widget.userId,
                    ),
                  ],
                ),
              ),
              
              // Enhanced draggable divider with smooth animations
              MouseRegion(
                cursor: SystemMouseCursors.resizeRow,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _isDragging = true;
                      final totalContent = MediaQuery.of(context).size.height - 100;
                      final newHeight = _leaderboardHeight + (details.delta.dy / totalContent);
                      
                      // Constrain between 15% and 40%
                      _leaderboardHeight = newHeight.clamp(0.15, 0.40);
                    });
                  },
                  onVerticalDragEnd: (_) {
                    setState(() {
                      _isDragging = false;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _isDragging ? 24 : 16,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.deepPurple.shade800.withOpacity(_isDragging ? 0.15 : 0.08),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Subtle grip dots
                        if (_isDragging)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(3, (index) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade300.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )),
                          ),
                        // Main divider line
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _isDragging ? 140 : 60,
                          height: 2.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.deepPurple.shade400.withOpacity(_isDragging ? 0.9 : 0.5),
                                Colors.deepPurple.shade600.withOpacity(_isDragging ? 1.0 : 0.6),
                                Colors.deepPurple.shade400.withOpacity(_isDragging ? 0.9 : 0.5),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: _isDragging ? [
                              BoxShadow(
                                color: Colors.deepPurple.shade400.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ] : [],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Chat section - takes remaining space
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: GameChat(
                    gameSession: widget.session,
                    userId: widget.userId,
                    userName: widget.userName,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getLeaderboardHeight(BuildContext context) {
    // Calculate available height (minus header)
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = 70.0; // Approximate header height
    final dividerHeight = 150.0;
    
    final availableHeight = screenHeight - headerHeight - dividerHeight;
    return availableHeight * _leaderboardHeight;
  }
}
