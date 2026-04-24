// lib/widgets/spark_line.dart

import 'package:flutter/material.dart';

class SparkLine extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double height;
  final double strokeWidth;
  final bool showFill;

  const SparkLine({
    super.key,
    required this.data,
    required this.color,
    this.height = 40,
    this.strokeWidth = 2.0,
    this.showFill = true,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(height: height);
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _SparkLinePainter(
          data: data,
          color: color,
          strokeWidth: strokeWidth,
          showFill: showFill,
        ),
      ),
    );
  }
}

class _SparkLinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double strokeWidth;
  final bool showFill;

  _SparkLinePainter({
    required this.data,
    required this.color,
    required this.strokeWidth,
    required this.showFill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;
    if (range == 0) return;

    final stepX = size.width / (data.length - 1);
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - ((data[i] - minVal) / range * size.height * 0.85) - size.height * 0.05;
      points.add(Offset(x, y));
    }

    // Fill gradient
    if (showFill) {
      final fillPath = Path()..moveTo(0, size.height);
      for (final p in points) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath.lineTo(size.width, size.height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);
    }

    // Line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      // Smooth curve using cubic bezier
      final prev = points[i - 1];
      final curr = points[i];
      final cp1x = prev.dx + (curr.dx - prev.dx) * 0.4;
      final cp2x = prev.dx + (curr.dx - prev.dx) * 0.6;
      linePath.cubicTo(cp1x, prev.dy, cp2x, curr.dy, curr.dx, curr.dy);
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    // End dot
    final lastPoint = points.last;
    canvas.drawCircle(
      lastPoint,
      3.5,
      Paint()..color = color,
    );
    canvas.drawCircle(
      lastPoint,
      6,
      Paint()..color = color.withValues(alpha: 0.25),
    );
  }

  @override
  bool shouldRepaint(covariant _SparkLinePainter old) =>
      data != old.data || color != old.color;
}
