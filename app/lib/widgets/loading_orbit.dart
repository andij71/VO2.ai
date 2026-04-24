// lib/widgets/loading_orbit.dart

import 'package:flutter/material.dart';
import '../core/constants.dart';

class LoadingOrbit extends StatefulWidget {
  final Color? color;
  final double size;

  const LoadingOrbit({super.key, this.color, this.size = 80});

  @override
  State<LoadingOrbit> createState() => _LoadingOrbitState();
}

class _LoadingOrbitState extends State<LoadingOrbit>
    with TickerProviderStateMixin {
  late final AnimationController _outer;
  late final AnimationController _inner;

  @override
  void initState() {
    super.initState();
    _outer = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _inner = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _outer.dispose();
    _inner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? AccentPreset.volt.primary;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          AnimatedBuilder(
            animation: _outer,
            builder: (_, child) => Transform.rotate(
              angle: _outer.value * 2 * 3.14159,
              child: child,
            ),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.1), width: 1.5),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                    boxShadow: [BoxShadow(color: accent, blurRadius: 12)],
                  ),
                ),
              ),
            ),
          ),
          // Inner ring
          AnimatedBuilder(
            animation: _inner,
            builder: (_, child) => Transform.rotate(
              angle: -_inner.value * 2 * 3.14159,
              child: child,
            ),
            child: Container(
              width: widget.size * 0.65,
              height: widget.size * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color.fromRGBO(255, 255, 255, 0.08),
                  width: 1.5,
                ),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF8B9EFF),
                    boxShadow: [BoxShadow(color: Color(0xFF8B9EFF), blurRadius: 10)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
