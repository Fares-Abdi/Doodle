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
  double _leaderboardHeight = 0.28; // 28% of available space, can be dragged from 15% to 40%
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
              
              // Leaderboard with draggable divider (Stack allows sparkle overflow)
              SizedBox(
                height: _getLeaderboardHeight(context),
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
              
              // Draggable divider with visual handle
              MouseRegion(
                cursor: SystemMouseCursors.resizeRow,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _isDragging = true;
                      final totalContent = MediaQuery.of(context).size.height - 100; // Rough content height
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
                  child: Container(
                    height: 24,
                    color: Colors.grey.shade50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _isDragging 
                                ? Colors.deepPurple.shade400
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
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
    final dividerHeight = 24.0;
    
    final availableHeight = screenHeight - headerHeight - dividerHeight;
    return availableHeight * _leaderboardHeight;
  }
}
