// lib/widgets/accent_pill.dart

import 'package:flutter/material.dart';
import '../core/constants.dart';

class AccentPill extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? backgroundColor;

  const AccentPill({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PaceRadii.pill),
        color: backgroundColor ?? const Color.fromRGBO(255, 255, 255, 0.08),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.14),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: color ?? const Color.fromRGBO(255, 255, 255, 0.7),
        ),
      ),
    );
  }
}
