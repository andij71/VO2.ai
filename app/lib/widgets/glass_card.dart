// lib/widgets/glass_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final bool glow;
  final Color? glowColor;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const GlassCard({
    super.key,
    required this.child,
    this.glow = false,
    this.glowColor,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PaceRadii.card),
        border: Border.all(color: PaceColors.cardBorder, width: 0.5),
        boxShadow: [
          if (glow && glowColor != null)
            BoxShadow(color: glowColor!, blurRadius: 40, spreadRadius: -8),
          const BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.35),
            blurRadius: 24,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PaceRadii.card),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Stack(
            children: [
              Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: PaceColors.cardBg,
                  borderRadius: BorderRadius.circular(PaceRadii.card),
                ),
                child: child,
              ),
              // Top shine highlight
              Positioned(
                top: 0,
                left: 24,
                right: 24,
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color.fromRGBO(255, 255, 255, 0.18),
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
  }
}
