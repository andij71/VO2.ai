// lib/widgets/ambient_background.dart

import 'package:flutter/material.dart';
import '../core/constants.dart';

class AmbientBackground extends StatefulWidget {
  final Widget child;
  final AccentPreset accent;

  const AmbientBackground({
    super.key,
    required this.child,
    this.accent = AccentPreset.volt,
  });

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: PaceColors.background),
        // Pulsing accent orb — top left
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final opacity = 0.08 + (_controller.value * 0.07);
            return Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.accent.primary.withValues(alpha: opacity),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            );
          },
        ),
        // Secondary orb — bottom right (periwinkle)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final opacity = 0.06 + ((1.0 - _controller.value) * 0.06);
            return Positioned(
              bottom: -60,
              right: -40,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF8B9EFF).withValues(alpha: opacity),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            );
          },
        ),
        // Content
        widget.child,
      ],
    );
  }
}
