import 'package:flutter/material.dart';
import '../../models/game_session.dart';
import '../../widgets/enhanced_leaderboard.dart';

class TestKeyboardVisibilityScreen extends StatefulWidget {
  @override
  _TestKeyboardVisibilityScreenState createState() => _TestKeyboardVisibilityScreenState();
}

class _TestKeyboardVisibilityScreenState extends State<TestKeyboardVisibilityScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  late AnimationController _panelController;
  late GameSession _testSession;
  
  // Divider variables
  late double _leaderboardHeight;
  late double _heightBeforeKeyboard;
  bool _isDragging = false;
  bool _isHoveringDivider = false;
  double _lastViewInsetsBottom = 0.0;
  late AnimationController _dragController;
  late AnimationController _dividerExpandController;
  late Animation<double> _dividerExpandAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _panelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _leaderboardHeight = 0.38;
    _heightBeforeKeyboard = 0.38;

    _dragController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _dividerExpandController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _dividerExpandAnimation = CurvedAnimation(
      parent: _dividerExpandController,
      curve: Curves.easeInOutCubic,
    );

    _dividerExpandController.value = 1.0;

    // Create a mock session for testing
    _testSession = GameSession(
      id: 'test-session',
      players: [
        Player(id: 'test-user', name: 'Test User', photoURL: 'purple'),
        Player(id: 'player-1', name: 'Player 1', photoURL: 'blue'),
        Player(id: 'player-2', name: 'Player 2', photoURL: 'green'),
      ],
      state: GameState.waiting,
    );

    _panelController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _chatController.dispose();
    _panelController.dispose();
    _dragController.dispose();
    _dividerExpandController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    _handleKeyboardVisibility(viewInsetsBottom);
  }

  void _handleKeyboardVisibility(double viewInsetsBottom) {
    final keyboardVisible = viewInsetsBottom > 0;
    final keyboardWasVisible = _lastViewInsetsBottom > 0;
    
    print('🔍 [TEST] Keyboard check - visible: $keyboardVisible, was visible: $keyboardWasVisible, isDragging: $_isDragging');
    
    if (!_isDragging && keyboardVisible != keyboardWasVisible) {
      print('✅ [TEST] Keyboard state changed! Updating leaderboard height');
      setState(() {
        if (keyboardVisible) {
          _heightBeforeKeyboard = _leaderboardHeight;
          _leaderboardHeight = 0.0;
          _dividerExpandController.forward();
          print('⌨️ [TEST] Keyboard visible - setting height to 0%');
        } else {
          _leaderboardHeight = _heightBeforeKeyboard;
          _dividerExpandController.reverse();
          print('🚫 [TEST] Keyboard hidden - restoring height to $_heightBeforeKeyboard');
        }
      });
    }
    
    _lastViewInsetsBottom = viewInsetsBottom;
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
            _leaderboardHeight = newHeight.clamp(0.0, 0.95);
            final percentage = (_leaderboardHeight * 100).toStringAsFixed(1);
            print('📊 [TEST] Divider dragging: $percentage%');
          });
        },
        onVerticalDragEnd: (_) {
          setState(() => _isDragging = false);
          if (!_isHoveringDivider) _dragController.reverse();
        },
        child: AnimatedBuilder(
          animation: _dividerExpandAnimation,
          builder: (context, child) {
            final expandValue = _dividerExpandAnimation.value;
            
            return Container(
              height: 12,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade400,
                    Colors.deepPurple.shade500,
                  ],
                ),
              ),
              child: Center(
                child: AnimatedBuilder(
                  animation: _dragController,
                  builder: (context, child) {
                    final animValue = Curves.easeOut.transform(_dragController.value);
                    return Opacity(
                      opacity: (0.3 + (0.3 * expandValue)) + (0.2 * animValue),
                      child: Container(
                        width: 120,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.95),
                              Colors.white.withOpacity(0.8),
                              Colors.grey.shade300.withOpacity(0.9),
                              Colors.white.withOpacity(0.85),
                            ],
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15 * (0.5 + (0.5 * expandValue))),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keyboard Visibility Test'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade700,
            ],
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Two side-by-side indicators for comparison
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Left: Actual keyboard detection
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isKeyboardVisible
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            border: Border.all(
                              color: isKeyboardVisible ? Colors.green : Colors.red,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ACTUAL KEYBOARD',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isKeyboardVisible ? Colors.green : Colors.red,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isKeyboardVisible ? '⌨️ VISIBLE' : '🚫 HIDDEN',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isKeyboardVisible ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Right: Divider detection
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.blue,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'DIVIDER STATUS',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isKeyboardVisible ? '46%' : '100%',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Text input field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tap here to open keyboard',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            
            // Chat panel on the right to test divider behavior
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(_panelController),
                child: Container(
                  width: 350,
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Header
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
                            Text(
                              isKeyboardVisible ? '⌨️ Keyboard Visible' : '✓ Keyboard Hidden',
                              style: const TextStyle(
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
                              'Height: ${(_leaderboardHeight * 100).toStringAsFixed(0)}%',
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
                      
                      // Leaderboard
                      Container(
                        height: _getLeaderboardHeight(context),
                        clipBehavior: Clip.none,
                        child: EnhancedLeaderboard(
                          session: _testSession,
                          userId: 'test-user',
                        ),
                      ),
                      
                      // Divider
                      _buildEnhancedDivider(),
                      
                      // Chat messages area (Expanded)
                      Expanded(
                        child: Container(
                          color: Colors.grey.shade100,
                          child: Center(
                            child: Text(
                              'Chat messages\n(Drag divider)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Message input - fixed at bottom of panel (not movable by divider)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        padding: EdgeInsets.only(
                          left: 12,
                          right: 12,
                          top: 8,
                          bottom: 8 + (MediaQuery.of(context).viewInsets.bottom == 0 ? _lastViewInsetsBottom : 0),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _chatController,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Colors.deepPurple,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.deepPurple.shade500,
                                    Colors.deepPurple.shade600,
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () {
                                  if (_chatController.text.isNotEmpty) {
                                    debugPrint('[TEST] Message sent: ${_chatController.text}');
                                    _chatController.clear();
                                  }
                                },
                                icon: const Icon(Icons.send, color: Colors.white),
                                iconSize: 20,
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
