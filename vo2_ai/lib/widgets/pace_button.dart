// lib/widgets/pace_button.dart

import 'package:flutter/material.dart';
import '../core/constants.dart';

class PaceButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? glowColor;
  final bool enabled;

  const PaceButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.glowColor,
    this.enabled = true,
  });

  @override
  State<PaceButton> createState() => _PaceButtonState();
}

class _PaceButtonState extends State<PaceButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? AccentPreset.volt.primary;
    final isEnabled = widget.enabled && widget.onPressed != null;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _scale = 0.97) : null,
      onTapUp: isEnabled ? (_) => setState(() => _scale = 1.0) : null,
      onTapCancel: isEnabled ? () => setState(() => _scale = 1.0) : null,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PaceRadii.button),
            color: isEnabled ? accent : const Color.fromRGBO(255, 255, 255, 0.08),
            boxShadow: isEnabled
                ? [BoxShadow(color: widget.glowColor ?? accent.withValues(alpha: 0.25), blurRadius: 24)]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: isEnabled ? const Color(0xFF0A0A0C) : PaceColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
