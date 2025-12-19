import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomLoadingScreen extends StatefulWidget {
  final String? message;

  const CustomLoadingScreen({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  State<CustomLoadingScreen> createState() => _CustomLoadingScreenState();
}

class _CustomLoadingScreenState extends State<CustomLoadingScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
            Colors.deepPurple.shade900,
            Colors.deepPurple.shade700,
            Colors.deepPurple.shade800,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Classic rotating spinner
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.9),
                ),
                strokeWidth: 4,
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            ),

            const SizedBox(height: 40),

            // Message text
            if (widget.message != null)
              Text(
                widget.message!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

/// Minimal loading spinner for inline use
class CompactLoadingSpinner extends StatefulWidget {
  final Color color;
  final double size;

  const CompactLoadingSpinner({
    Key? key,
    this.color = Colors.deepPurple,
    this.size = 24,
  }) : super(key: key);

  @override
  State<CompactLoadingSpinner> createState() => _CompactLoadingSpinnerState();
}

class _CompactLoadingSpinnerState extends State<CompactLoadingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.color.withOpacity(0.2),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(widget.size / 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.size / 2),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: widget.color,
                          width: 2,
                        ),
                        right: BorderSide(
                          color: widget.color,
                          width: 2,
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
}
