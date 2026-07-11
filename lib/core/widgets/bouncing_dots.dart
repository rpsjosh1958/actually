import 'dart:math';
import 'package:flutter/material.dart';

/// Three dots bouncing one at a time, left to right, in a continuous wave —
/// the app's own loading indicator (echoes the "..." in the ACTUALLY
/// wordmark) used in place of the default Material spinner everywhere.
class BouncingDots extends StatefulWidget {
  final Color color;
  final double dotSize;

  const BouncingDots({super.key, required this.color, this.dotSize = 14});

  @override
  State<BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<BouncingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _bounceFor(int index) {
    final localT = (_controller.value - index * 0.22) % 1.0;
    return localT < 0.35 ? sin(localT / 0.35 * pi) : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (i) => Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.dotSize * 0.42),
            child: Transform.translate(
              offset: Offset(0, -widget.dotSize * _bounceFor(i)),
              child: Container(
                width: widget.dotSize,
                height: widget.dotSize,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
