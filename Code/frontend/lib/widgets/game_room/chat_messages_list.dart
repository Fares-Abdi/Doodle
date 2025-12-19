import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import 'chat_bubble.dart';

class ChatMessagesList extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final ScrollController controller;
  final String userId;
  final GameSession session;

  const ChatMessagesList({
    Key? key,
    required this.messages,
    required this.controller,
    required this.userId,
    required this.session,
  }) : super(key: key);

  @override
  State<ChatMessagesList> createState() => _ChatMessagesListState();
}

class _ChatMessagesListState extends State<ChatMessagesList> {
  final Set<String> _animatedMessages = {};
  
  @override
  void didUpdateWidget(ChatMessagesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Mark old messages as already animated
    for (var msg in oldWidget.messages) {
      final msgId = '${msg['userId']}_${msg['timestamp'] ?? msg.hashCode}';
      _animatedMessages.add(msgId);
    }
    
    // Auto-scroll to bottom when new messages arrive
    if (widget.messages.length > oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (widget.controller.hasClients) {
            widget.controller.jumpTo(widget.controller.position.maxScrollExtent);
          }
        });
      });
    }
  }

  Widget _buildRoundDivider(int roundNumber, {bool isAnimated = true}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: isAnimated ? 500 : 0),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.7 + (0.3 * value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.deepPurple.shade200.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.shade400,
                          Colors.deepPurple.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          size: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Round $roundNumber',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurple.shade200.withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedMessage(
    Map<String, dynamic> message,
    int index,
  ) {
    final msgId = '${message['userId']}_${message['timestamp'] ?? message.hashCode}';
    final isNewMessage = !_animatedMessages.contains(msgId);
    final isCurrentUser = message['userId'] == widget.userId;
    
    // Only animate new messages
    if (isNewMessage) {
      return TweenAnimationBuilder<double>(
        key: ValueKey(msgId),
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.elasticOut,
        onEnd: () {
          if (mounted) {
            setState(() {
              _animatedMessages.add(msgId);
            });
          }
        },
        builder: (context, value, child) {
          // Clamp opacity to valid range [0.0, 1.0]
          final clampedOpacity = value.clamp(0.0, 1.0);
          
          // Slide in from the side (right for current user, left for others)
          final slideOffset = isCurrentUser ? 100.0 : -100.0;
          
          return Transform.translate(
            offset: Offset(slideOffset * (1 - clampedOpacity), 0),
            child: Transform.scale(
              scale: 0.5 + (0.5 * clampedOpacity),
              alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Opacity(
                opacity: clampedOpacity,
                child: child,
              ),
            ),
          );
        },
        child: ChatBubble(
          message: message,
          isCurrentUser: isCurrentUser,
          session: widget.session,
        ),
      );
    }
    
    // Already animated messages - show immediately
    return ChatBubble(
      key: ValueKey(msgId),
      message: message,
      isCurrentUser: isCurrentUser,
      session: widget.session,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 800),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 48,
                      color: Colors.deepPurple.shade300,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start guessing to chat with players!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return Stack(
        children: [
          _buildEmptyState(),
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: _buildRoundDivider(widget.session.currentRound),
          ),
        ],
      );
    }

    final List<Widget> items = [];
    int? lastDividerRound;
    
    for (int i = 0; i < widget.messages.length; i++) {
      final message = widget.messages[i];
      final messageRound = message['roundNumber'] ?? 0;
      
      // Show divider if this is a new round
      if (lastDividerRound == null || messageRound != lastDividerRound) {
        // Only animate the most recent round dividers
        final isRecentRound = widget.messages.length - i < 10;
        items.add(_buildRoundDivider(messageRound, isAnimated: isRecentRound));
        lastDividerRound = messageRound;
      }
      
      items.add(_buildAnimatedMessage(message, i));
    }
    
    // If current round has no messages yet, show its divider at the end
    if (lastDividerRound != widget.session.currentRound) {
      items.add(_buildRoundDivider(widget.session.currentRound));
    }
    
    return ListView(
      controller: widget.controller,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      physics: const BouncingScrollPhysics(),
      children: items,
    );
  }
}