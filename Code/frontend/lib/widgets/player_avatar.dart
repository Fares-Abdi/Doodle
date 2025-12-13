import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../utils/avatar_color_helper.dart';

class PlayerAvatar extends StatefulWidget {
  final Player player;
  final bool isCurrentUser;
  final bool isNewPlayer;
  final bool isLeavingPlayer;
  final VoidCallback? onAnimationEnd;

  const PlayerAvatar({
    Key? key,
    required this.player,
    this.isCurrentUser = false,
    this.isNewPlayer = false,
    this.isLeavingPlayer = false,
    this.onAnimationEnd,
  }) : super(key: key);

  @override
  State<PlayerAvatar> createState() => _PlayerAvatarState();
}

class _PlayerAvatarState extends State<PlayerAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    if (widget.isLeavingPlayer) {
      // Leave animation: scale down and fade out
      _scaleAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn),
      );
      _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn),
      );
      _controller.forward();
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onAnimationEnd?.call();
        }
      });
    } else if (widget.isNewPlayer) {
      // Join animation: scale up and fade in
      _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _controller.forward();
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onAnimationEnd?.call();
        }
      });
    } else {
      // No animation for existing players
      _scaleAnimation = AlwaysStoppedAnimation<double>(1.0);
      _opacityAnimation = AlwaysStoppedAnimation<double>(1.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = AvatarColorHelper.getColorFromName(widget.player.photoURL);
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: widget.isCurrentUser ? 40 : 30,
                      backgroundColor: avatarColor,
                      child: Text(
                        widget.player.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: widget.isCurrentUser ? 24 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Show creator badge
                    if (widget.player.isCreator)
                      Positioned(
                        top: -5,
                        right: -5,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.player.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
