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

class _ChatPanelState extends State<ChatPanel> with TickerProviderStateMixin {
  double _leaderboardHeight = 0.38; // 38% by default - shows full gold medal position
  late double _panelContentHeight;
  bool _isDragging = false;
  bool _isHoveringDivider = false;
  late AnimationController _dragController;

  @override
  void initState() {
    super.initState();
    _dragController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

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
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.deepPurple.shade900.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.shade900.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.deepPurple.shade200.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
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
              
              // Enhanced draggable divider
              _buildEnhancedDivider(),
              
              // Chat section - takes remaining space
              _buildChatSection(),
            ],
          ),
        ),
      ),
    );
  }

  double _getLeaderboardHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = 130.0;
    final dividerHeight = 28.0;
    
    final availableHeight = screenHeight - headerHeight - dividerHeight;
    return availableHeight * _leaderboardHeight;
  }

  Widget _buildEnhancedDivider() {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      onEnter: (_) {
        setState(() => _isHoveringDivider = true);
        _dragController.forward();
      },
      onExit: (_) {
        setState(() => _isHoveringDivider = false);
        if (!_isDragging) _dragController.reverse();
      },
      child: GestureDetector(
        onVerticalDragStart: (_) {
          setState(() => _isDragging = true);
          _dragController.forward();
        },
        onVerticalDragUpdate: (details) {
          setState(() {
            final totalContent = MediaQuery.of(context).size.height - 100;
            final newHeight = _leaderboardHeight + (details.delta.dy / totalContent);
            _leaderboardHeight = newHeight.clamp(0.15, 0.45);
          });
        },
        onVerticalDragEnd: (_) {
          setState(() => _isDragging = false);
          if (!_isHoveringDivider) _dragController.reverse();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 12,
          decoration: BoxDecoration(
            color: _isDragging || _isHoveringDivider
                ? const Color.fromARGB(255, 102, 0, 255).withOpacity(0.4)
                : const Color.fromARGB(255, 102, 0, 255).withOpacity(0.25),
            border: Border(
              top: BorderSide(
                color: _isDragging || _isHoveringDivider
                    ? Colors.deepPurple.shade400.withOpacity(0.4)
                    : Colors.deepPurple.shade300.withOpacity(0.3),
                width: 1,
              ),
              bottom: BorderSide(
                color: _isDragging || _isHoveringDivider
                    ? Colors.deepPurple.shade400.withOpacity(0.3)
                    : Colors.deepPurple.shade200.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _dragController,
              builder: (context, child) {
                final animValue = Curves.easeOut.transform(_dragController.value);
                return Container(
                  width: 40 + (80 * animValue),
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (_isDragging || _isHoveringDivider
                            ? const Color(0xFF6366F1)
                            : Colors.deepPurple.shade500).withOpacity(0.7),
                        (_isDragging || _isHoveringDivider
                            ? const Color(0xFF8B5CF6)
                            : Colors.deepPurple.shade600).withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatSection() {
    return Expanded(
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
    );
  }
}
